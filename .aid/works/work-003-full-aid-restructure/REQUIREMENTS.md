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
    to: aid-kb-update
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
| The business part of `REQUIREMENTS.md`, before the technical part is designed (Specification; Feature 005, Q61) | approve | -- |
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
  - **one stage rail per work** (Q75): `renderStageRail` draws the work's own `intent.phases` (Feature 001),
    which both readers pass with the work, plus Done; a work with no `intent.phases` uses `PHASE_ORDER`. The
    stage is Done when `lifecycle` is `Completed`, else the one `phase` names. `_renderLiteStageRail` and
    `LITE_STAGES` go, and the comments above `renderStageRail` that name the old phases are rewritten with it.
  The readers hand the page only new names, so the page holds no old-name mapping. The work card shows the
  phase, one plain line from `step_detail`, "Waiting for your answer (N)" when open questions exist, and
  "Away in /aid-kb-update -- back to Building after" while a call is open. No step names, no maps.
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
  `node:vm`), takes `PHASE_ORDER` and `renderStageRail` from `home.html` by name, runs them against a small
  stand-in for the page, and checks the stages drawn and the marked stage for works with different
  `intent.phases` at each phase -- e.g. a work without Definition at `Building` marks the Building stage, not
  the first one -- and for a work with no `intent.phases`.
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
| Edit | `canonical/aid/scripts/execute/writeback-state.sh` | `--pipeline` accepts the fields `"Idea Draft"` (key `idea_draft`) and `"Side Idea"` (key `side_idea`); value `--` or `.aid/design/<name>.md` (lowercase letters, digits and hyphens), anything else exit 4 |
| Edit | `canonical/aid/templates/work-state-template.yml` | `idea_draft: --` and `side_idea: --` with their `[W]` comments; the `sources[].kind` comment gains `draft` |
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
- **Tracked on a work's branch**: in that work's worktree, `.aid/design/<name>.md`, when git tracks it on the
  branch checked out there -- because the user chose to keep it with the work, or because the work inherited
  it from its parent branch (a seed someone committed by hand).

There is no third state. The work record stores only identities, `.aid/design/<name>.md`: `idea_draft` for the
work's own draft, `side_idea` while a side idea is talked through (see Flow), and a `sources:` entry of kind
`draft` for a side idea taken into the work. **Every reader and writer resolves the live copy with
`idea-drafts.sh path` first** -- `aid-brainstorm`, the deletion rule, and Feature 005 when Specification reads
the work's draft and its `draft` sources -- and never opens an identity as a path inside a worktree. A sub-agent never touches the draft: it returns text, and the main conversation writes it.

`idea-drafts.sh` is the only code that moves, commits or deletes a draft:

| Operation | Does |
|---|---|
| `dir` | Prints the absolute path of the main folder's `.aid/design/` (the main worktree, resolved the way `worktree-lifecycle.sh` resolves it, from any worktree); without git, the project folder's `.aid/design/` |
| `path <name>` | Prints the live copy: the current worktree's `.aid/design/<name>.md` when git tracks it on the current branch, otherwise `dir`'s `<name>.md` |
| `list` | One line per draft (name, first line under `## Problem`): loose ones in the main folder; ones kept on a work's branch, marked with that work; ones left untracked in another worktree by an old run (KI-004), marked with that worktree |
| `collect <name> --from <worktree>` | Moves such a left-behind draft into the main folder, loose |
| `keep <name>` | Run inside a work's worktree: moves the loose draft into it and commits that path alone on the work's branch; run again, commits the draft's later changes |
| `release <name>` | The reverse: copies the worktree copy to the main folder, loose, and commits the draft's removal from the work's branch (that path alone) |
| `delete <name>` | Loose: removes the file. Tracked on the current branch: removes it and commits the removal (that path alone) on that branch |

- Exit codes: 0 done; 2 a bad `<name>` (only lowercase letters, digits and hyphens; `README` refused) or a
  path outside `.aid/design/`, checked before anything runs; 3 git needed and absent; 4 the branch cannot
  take a commit (none checked out, a merge or rebase in progress) or `keep` / `release` run outside a work's
  worktree; 5 no such draft.
- **No push, ever.** The script has no `git push`, and no other code stages `.aid/design/`.

**Committing is never the default (Q50, Q52).** A draft is committed only on a work's branch, and only by
the user's choice:
- **Every path that ends with a draft belonging to a work asks the Q44 question** "Keep the draft with this
  work?" -- at FINISH when the work's own idea goes on, and when a side idea is taken into the work (see
  Flow). Importance low; recommendation **no**, because the draft is deleted at the covering approval and
  stays in the main folder meanwhile. Yes runs `keep`: the draft is committed on **that work's branch**, and
  re-committed when the user pauses or ends the conversation. It is removed from the branch at the
  covering approval (below), so the PR/MR's final content never holds it -- its history may (AC-35). The
  user may also ask to keep it at any moment.
- **An idea set aside** -- a parked idea, or a side idea kept apart from its work -- gets one question (Q52):
  - *Keep it as a draft* -- loose in the main folder, uncommitted; the agent says plainly that it is lost if
    that folder is deleted;
  - *Keep it in a work* -- the draft is committed on a work's branch (`keep`), which the user may push to back
    it up; which work is set in Flow (parking, side ideas). Recommended where Flow says so.
- With no git, nothing is committed: *Keep it in a work* only keeps a work open for the idea, and the keep
  question is not asked.

**Deletion (M5, AC-17)** -- `skill-steps.md` § When approvals happen gains one rule, applied right after the
approval is recorded, to the work's `idea_draft` and every `sources:` entry of kind `draft`:

| The draft | Deleted at |
|---|---|
| The work's own draft handed to Specification; a side idea taken into a work in Definition or Specification | the `REQUIREMENTS.md` approval (`full`) or the confirmation before building (`lite`) |
| The work's own draft handed to a KB update | the approval of the KB change (owed by Feature 004, see Flow) |

The approval's own message says the draft will be removed, so the user's yes covers it. `idea-drafts.sh
delete` then removes the live copy -- committing the removal when the draft is tracked on the work's branch,
including one inherited from the parent branch, whose removal the PR/MR then carries. `idea_draft` is cleared
(`--pipeline --field "Idea Draft" --value --`); a `draft` source keeps its entry, its `effect` noting the
deletion. A draft kept in a work of its own follows that work's approvals.

**Name**: a new draft takes the work's short name, asked once at intake (Feature 002). A draft picked up
again keeps its own name. When the name is taken by an unrelated draft, the agent proposes `<name>-2` as a
confirmation question. A work has **one own draft**, `idea_draft`. A side idea is always a new, standalone
draft with its own name: it never continues or changes the work's own draft.

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
   A draft kept in a work is not offered here (see Parking for how it is picked up).
   Otherwise create the draft from `design-seed.md`. Write the folder README on first use. Record
   `idea_draft` -- or, for a side idea, `side_idea`, always for a new draft and never the work's own.
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
     aid-kb-update --step <its entry step> --returns no --why ...`, with no `--phase` (Preparation is not a
     work phase); what happens next is Feature 004's (below);
   - *Keep it for later* -- **park** it.
3. **Keep the draft with this work?** -- asked only when the idea goes on and git exists, and skipped when
   the draft is already committed on this work's branch (a work resumed after *Keep it in a work*, or the new
   work made for a side idea kept in a work); importance low;
   recommendation **no**, because the draft is deleted at the next covering approval and stays safe in the
   main folder meanwhile; yes runs `keep`. The user may also ask to keep it at any moment in CONVERSE.

**Parking** -- only when the brainstorm is the work's own idea (in Definition); during a side idea, "keep it
for later" follows the side-idea rules below. Choosing *Keep it for later*, or saying so at any question. The answer that chooses it is the
confirmation; said elsewhere, one confirmation question comes first ("Set this idea aside for later?"). Then
the set-aside question (The idea draft):
- *Keep it in a work* (recommended: the idea survives losing the folder and resumes where it stopped) -- this
  work stays open for it: the draft is committed on its branch (`keep`), and the work is paused at CONVERSE
  (`lifecycle: Paused-Awaiting-Input`, `pause_reason: 'Idea kept for later'`);
- *Keep it as a draft* -- a draft kept with the work is `release`d to the main folder, and the work is
  cancelled the way `/aid-orchestrate` cancels one (`writeback-state.sh --pipeline --field Lifecycle --value
  Canceled`).

The user is told in one line how to pick the idea up. *Keep it as a draft*: say so, and START offers it.
*Keep it in a work*: that work is paused, so it is an open work, and the gate's existing "new work or
continue" question (Feature 002, before any `--create`) offers it; continuing it follows the normal resume
from its work record and goes on at CONVERSE. START is not involved, and a side idea never takes it (a side
idea is always a new standalone draft). Pausing is not parking.

**As a side idea** -- brainstorm runs inside a work that continues: an open call from another skill, or a
typed start on a work already past Definition. **The work is never cancelled and its own draft is never
touched**: the side idea is its own new draft, recorded as `side_idea`. No approval of the draft (it is not
in the approvals table outside Definition). One question, where it goes:
- *Back into the work* -- offered only while the work is in Definition or Specification, and recommended
  then: the draft is added to the work's `sources:` as kind `draft` (Feature 001's list), Feature 005 reads
  it as an extra source, and it is deleted at the requirements approval or the confirmation before
  building (deletion table). Then the keep question (The idea draft);
- *Keep it in a work* (recommended once the work is past Specification) -- a small new work is created for
  it through the gate's § 3a (`--skill aid-brainstorm --step CONVERSE --phase Definition`, its request the
  side idea's problem), the draft is committed on that work's branch (`keep`), the new work's `idea_draft`
  is recorded with the same write START uses (`--pipeline --field "Idea Draft"`), so its resume finds the
  draft and the deletion rule fires before its PR/MR; the new work is paused at CONVERSE, and the agent goes
  back to the original work's worktree (`worktree-lifecycle.sh locate`). It is picked up like a parked idea
  kept in a work: by resuming it;
- *Keep it as a draft* -- it stays loose in the main folder, and the agent says it is lost if that folder is
  deleted.

Saying "keep it for later" at any point of a side idea leads to this same question, without *Back into the
work*: the current work is never paused, cancelled or committed to.

Then `side_idea` is cleared, and the work goes back where it was: `HALT`, which returns to the open call; or,
after a typed start, `PASS` back to the skill that drives the work's phase, at its entry step, without
`--phase`.

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
  left untracked in another worktree, and `collect` moves it, and a draft kept on another work's branch,
  marked with that work; `keep` moves the draft into the worktree and commits only that path on the work's
  branch, and refuses in the main folder; `release` restores the loose copy and commits only the removal;
  `delete` removes a loose draft without a commit, and a tracked one with a removal commit of that path
  alone; another staged file is never committed; nothing ever changes the main folder's branch;
  exit 3 without git, 4 on a detached head or during a merge, 5 for an unknown draft, 2 for
  `README`, a name with `/` or `..`, or a path outside `.aid/design/`, each changing nothing.
- `tests/canonical/test-writeback-state.sh`: `--pipeline --field "Idea Draft"` and `--field "Side Idea"`
  accept `--` and a valid identity, refuse any other value with exit 4; the file still parses through the dashboard reader.

**Conversation samples -- `tests/conversation/samples/feature-003/`** (frontmatter `skills: aid-brainstorm`)

| Sample | Covers | Runs |
|---|---|---|
| `003-01-conversation-across-sessions` -- a bare idea; the agent proposes options and challenges, the user pauses; a second session by another persona continues; check: the draft in the main folder updated after every exchange, `## Where we left off` and `step_detail` match the last subject, the second session picks up there, no wrap-up is suggested, and the conversation ends only when the user says so | AC-17, AC-28, AC-37 | now |
| `003-02-design-a-kind` -- "design the orders API"; check: no `aid-design*` skill exists or is run, the draft's `## Kind` is `api` and api's `shape` points are raised early, no KB or code file written | AC-43, AC-28 | now |
| `003-03-unclear-ticket` -- a ticket exported as a file, whose problem is unclear; check: a `sources:` entry, the draft's `## Sources` names it, questions the ticket answers are not asked | AC-28 | now |
| `003-04-park-as-draft` -- the user parks the idea and keeps it as a draft; a later session picks it up; check: the work `Canceled`, the draft loose and uncommitted in the main folder, the agent said it is lost if that folder is deleted, no commit made anywhere, the new work's START offers it | AC-17 | now |
| `003-05-park-in-a-work` -- the user parks the idea and keeps it in a work; a later session asks to continue that work; check: the work not cancelled but paused at CONVERSE, one commit on the work's branch touching only the draft, nothing committed in the main folder, nothing pushed, the later session resumes that work from its record at CONVERSE, and no new work is created | AC-17 | now |
| `003-06-side-idea-into-specification` -- fixture: a work in Specification with its own `idea_draft`; the user brainstorms a side idea and takes it back into the work; check: a new draft with its own name, the work's own draft unchanged and still its `idea_draft`, a `sources:` entry of kind `draft`, the keep question asked, the work not cancelled, its skill and phase restored | AC-17, AC-37 | deferred: Feature 005 |
| `003-07-side-idea-in-building` -- fixture: a work in Building that reached brainstorm by an open call (a `handoffs` entry with `returns: 'yes'`); check: FINISH offers only *Keep it in a work* and *Keep it as a draft*; with the first, a new paused work holds the draft committed on its own branch only, with its `idea_draft` recorded, the original work resumes at its saved step (`HALT` returns the call), and its `sources:` gains nothing. Run also as a typed start: the work goes back by `PASS` at its phase skill's entry step | AC-17, AC-37 | deferred: Feature 007 |
| `003-08-finish-next-step` -- check: the next-step question recommends the kind's `then`, the user's choice is recorded, and the hand-off goes where the user chose | AC-17, AC-38 | deferred: Feature 005 |
| `003-09-kept-draft-removed-at-approval` -- the user keeps the draft with the work; check: committed on the work's branch only, removed with a commit at the `REQUIREMENTS.md` approval, the branch's final content holds no draft, `idea_draft` cleared | AC-17, AC-35 | deferred: Feature 005 |
| `003-10-deleted-at-lite-confirmation` | AC-17 | deferred: Feature 007 |
| `003-11-roadmap-to-kb` -- "let's rethink the roadmap"; check: KB update recommended and chosen, the roadmap KB document updated, the draft deleted at the KB change approval, the work closed as done | AC-43 | deferred: Feature 004 (needs: the `KB change` approval row and the KB update skill's close, Flow) |

**Deferred list** (`tests/conversation/deferred.tsv`): the rows `skill:aid-brainstorm`, `skill:aid-describe`,
`skill:aid-design` and `skill:aid-design-*` go (the first is covered by these samples, the others leave with
their skills); `002-12` now waits only for Feature 005 and `002-08` for Features 005, 006 and 007; the
deferred samples above are added, `003-11` with the two Feature 004 needs in its `needs` column. Feature
001's `001-08-bare-idea` is run again at this feature's end.

##### Criteria traceability

| Criterion | Where satisfied | How verified |
|---|---|---|
| AC-17 | The idea draft (the two states, the record, `idea-drafts.sh`, the deletion rule, commits only by the user's choice); Flow (START, CONVERSE, FINISH, parking, side ideas) | ID-03, ID-05, ID-06, ID-07; `test-idea-drafts.sh`; writer unit tests; `003-01`, `003-04`, `003-05`; `003-06` to `003-10` (deferred) |
| AC-43 | Files and layout (deletions); Kinds of things; Components (routing, the kept invariant) | ID-01 to ID-04; `003-02`; `003-11` (deferred) |

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

Serves FR-2, FR-10 and FR-14, and follows FR-6, FR-8, FR-17, FR-18 and FR-20 as Features 001-003 define
them. Maintainer decisions: Q7, Q10, Q15, Q16, Q17, Q38, Q39, Q47, Q53-Q58. Paths are `canonical/`
sources, rendered as in Feature 001. "The view" is `.aid/knowledge/kb.html`; "the KB state file" is
`.aid/knowledge/STATE.yml`.

##### 1. Files and layout

| Change | Path | What |
|---|---|---|
| Move + rewrite | `canonical/skills/aid-discover/` -> `canonical/skills/aid-kb-build/` | `SKILL.md` rewritten: its step table (see Flows), `skill-steps.md` and `question-protocol.md` cited, Feature 001's what/when `description:`, at most 150 lines. Goes: `--reset` (a rebuild is a plain request, see Flows), `--grade` (the bar is `.aid/settings.yml` `minimum_grade`), § Targeted Discovery (Re-entry) (`/aid-kb-update` does it), the state map. The dispatch-visibility checklist stays, as a pointer to `long-wait-protocol.md`. The references move with the skill; they change where Flows says, and every retired name or old path in them is re-pointed (Migration, Re-pointing): `state-elicit.md` -> `elicit.md`, `state-generate.md` -> `generate.md` (Step 7 goes: no installed `AGENTS.md` carries its `AID-DISCOVER` placeholders), `state-review.md` -> `review.md`, `state-q-and-a.md` -> `questions.md`, `state-fix.md` -> `fix.md`, `state-approval.md` -> `approve.md`, `state-done.md` -> `finish.md`; `document-expectations.md` loses its `greenfield: true` mode; new `start.md`, at most 120 lines |
| Move + rewrite | `canonical/skills/aid-update-kb/` -> `canonical/skills/aid-kb-update/` | `SKILL.md` rewritten, at most 120 lines. Goes: Pre-flight ISOLATE (its own worktree, `aid/update-kb-<ts>` branch, prompt matching, `.aid/.temp/UPDATEKB_STATE_*.md`), because it always runs inside a work. Kept and edited: `state-analyze.md` -> `analyze.md`, `state-scope.md` -> `scope.md`, `state-confirm.md` -> `confirm.md`, `state-apply.md` -> `apply.md`, `state-review.md` -> `review.md`. `state-approval.md` and `state-done.md` merge into `finish.md`. New, each at most 120 lines: `start.md`, `sweep.md` (from `aid-housekeep/references/state-kb-delta.md`, its conformance check included), `new-document.md` (creating and registering a document, from the retiring `create` skills), `reviewer-brief.md` (with `### What to report`, SS-13) |
| Move + edit | `canonical/skills/aid-ask/` -> `canonical/skills/aid-kb-query/` | New name and description; gap capture through the writer (see Flows); `allowed-tools` becomes `Read Glob Grep Bash Agent` |
| Create | `canonical/skills/aid-kb-show/SKILL.md` | The link to the view (see Flows); at most 60 lines; `allowed-tools: Read Glob Bash` |
| Delete | `canonical/skills/aid-summarize/`, `canonical/skills/aid-housekeep/` | Absorbed (FR-2, Q7, Q15) |
| Delete | `canonical/skills/aid-create-*/` and `canonical/skills/aid-update-*/` for `architecture`, `stack`, `testing-strategy`, `cicd`, `roadmap`, `backlog`, `mvp` | Absorbed by `/aid-kb-update` (Q7, FR-14) |
| Delete | `canonical/aid/templates/design-lifecycle.md` | Its last users are the skills above |
| Edit | `canonical/aid/templates/shortcut-catalog.yml` | The rows of the deleted `create` / `update` skills go, with any comment naming them |
| Delete | `canonical/aid/scripts/summarize/` | Every script goes; `contrast-check.mjs` moves to `tests/canonical/lib/` (Testing) |
| Delete | `canonical/aid/scripts/housekeep/branch-commit.sh`, `housekeep-state.sh`; `canonical/aid/scripts/kb/discover-preflight.sh` | `cleanup-classify.sh` stays for Feature 008 (What other features must provide) |
| Delete (part) | `canonical/aid/templates/knowledge-summary/` | `prompt.md`, `grading-rubric.md`, `authored-visual-catalog.md` and `section-templates/` go. `html-skeleton.html`, `component-css.css`, `lightbox.js`, `design-tokens.md` and `accessibility-checklist.md` stay as the renderer's inputs |
| Create | `canonical/aid/scripts/kb/render-kb-view.sh` | The view's renderer (see The view) |
| Create | `canonical/aid/scripts/kb/kb-commit.sh` | The one commit of KB paths (see Components) |
| Edit | `canonical/aid/scripts/kb/build-kb-index.sh` | No timestamp in its output (see The view); its header names `/aid-kb-build` and `/aid-kb-update` |
| Replace | `canonical/aid/templates/discovery-state-template.md` -> `canonical/aid/templates/kb-state-template.yml` | The KB state file's template (see The KB state file) |
| Create | `canonical/aid/templates/knowledge-base/roadmap.md`, `backlog.md` | The two documents' shapes, taken from `aid-create-roadmap` (the `## MVP` section included) and `aid-create-backlog`; type `template-payload` |
| Edit | `canonical/aid/scripts/execute/writeback-state.sh` | The `--kb` target, the KB modes, `--kb-update-log`, and `--create --parent-branch` (see The KB state file) |
| Edit | `canonical/aid/templates/work-state-template.yml` | `kb_updates: []` and `pipeline.parent_branch: --`, each with its `[W]` comment (see The KB state file) |
| Edit | `canonical/aid/templates/skill-steps.md` (Feature 002) | § When approvals happen gains two rows; new § The KB build record (see Components) |
| Edit | `canonical/aid/templates/question-protocol.md` (Feature 002) | Its "Where" bullet: KB building writes through `--ask --kb` / `--answer --kb` |
| Edit | `canonical/skills/aid-orchestrate/references/start-or-resume.md`, `size-and-route.md`, `feedback-routing.md` (Feature 001) | The drift check, the build's resume offer, the routing rows (see Components) |
| Edit | `canonical/skills/aid-orchestrate/references/check-intent.md` (Feature 001) | Reads `backlog.md` for "the next backlog item" and records it as a work source (see Components, Roadmap, backlog and MVP) |
| Edit | `canonical/skills/aid-brainstorm/references/finish.md` (Feature 003) | The KB-update hand-off targets `aid-kb-update`, and is offered only when a KB exists (see Components, No KB: one rule) |
| Edit | `canonical/aid/templates/work-initiation-gate.md` § 3a (Feature 002) | The new-project step, run before the worktree is created (see Components, A new project) |
| Edit | `canonical/aid/templates/work-initiation-gate.md` § 3a, `canonical/aid/scripts/works/worktree-lifecycle.sh` (the `--base` default and its `master` lines), `canonical/aid/templates/worktree-lifecycle.md` | Q60: a new work's worktree branches from the main folder's current branch, which is the work's parent branch (its pull-request target). The hard-coded `master` default goes: `create` takes the main folder's checked-out branch when `--base` is not given, and refuses with a plain message (exit 2) when that folder has no branch checked out. § 3a passes the branch to `--create --parent-branch` |
| Edit | `canonical/aid/templates/work-initiation-gate.md` § 3b legacy block (Feature 002) | One row for old works of the deleted `create` / `update` skills (see Migration) |
| Edit | `canonical/aid/rules.md` | The tracking line and the connectors line (see Components); in § Skill guide the lines of the retired skills go and four lines come |
| Edit | `canonical/aid/templates/settings.yml`, `canonical/skills/aid-config/SKILL.md` (the `knowledge` row) | `knowledge.source` and `knowledge.last_update` are no longer written or read (see Dashboard); `doc_set` and `term_exclusions` stay |
| Edit | `canonical/aid/scripts/execute/complexity-score.sh`; `canonical/skills/aid-execute/references/state-execute.md` § PD-0 | The script stops reading KB state for its thresholds (it keeps its defaults); the PD-0 wording names `.aid/settings.yml`, which it already reads |
| Edit | `bin/aid`, `bin/aid.ps1`, `lib/AidInstallCore.psm1`, `lib/aid-install-core.sh`, `canonical/aid/templates/settings.yml` (`format_version`) | Format 6 and the KB step of the conversion (see Migration) |
| Edit | `dashboard/reader/models.py`, `parsers.py`, `derivation.py`, `reader.py`, `dashboard/server/reader.mjs`, `dashboard/server/server.py` and `server.mjs` (the KB state passed to the page), `dashboard/home.html` (the KB card) | See Dashboard |
| Delete | the repository-root `package.json` and its entry in `.github/dependabot.yml` | Their only purpose was the view's Playwright check |
| Edit | `.github/workflows/test.yml`, `release.yml` | The summarize validator steps and comments go |
| Edit | every other kept file under `canonical/`, and `dashboard/home.html`, that names a retired skill, a moved reference by its old path, or `.aid/knowledge/STATE.md` | Re-pointed by one rule (Migration, Re-pointing) |
| Create | `tests/canonical/test-kb-skills.sh`, `test-render-kb-view.sh`, `test-kb-commit.sh`, `test-kb-state-migration.sh`, `tests/canonical/lib/contrast-check.mjs`, `tests/conversation/samples/feature-004/` | See Testing |

##### 2. The KB state file

`.aid/knowledge/STATE.yml` replaces `.aid/knowledge/STATE.md` (Q39). It follows Feature 002's block-style
rule, and only `writeback-state.sh --kb` writes it. It holds **only what building the KB needs**, plus
the questions about the KB asked outside any work. A KB
change made inside a work is recorded in that work's `STATE.yml`, never here, so branches never collide
on this file.

```yaml
# [W] Building | Approved | Growing; -- only in the template (the creating write sets it)
status: --
# [W] the skill building the KB now, or none -- only aid-kb-build is ever saved here
active_skill: none
# [W] its saved step; -- when none
step: --
# [W] where inside the step, in plain words; -- when none
step_detail: --
# [W] the last build review's grade (A+ .. F), or Pending
grade: Pending
# [W] 'yes' once the user approved the built KB
user_approved: 'no'
# [W] the commit the approved build describes; -- before the first approval
baseline: --
# [W] the confirmed project domain, e.g. hybrid:methodology-tooling+software-cli; --
domain: --
# [W] the confirmed discovery path, e.g. brownfield-large; --
triage: --
# [W] 'yes' once this build's external sources and connectors are settled
elicitation: 'no'
# [W] one entry per document of the set: doc, status (Pending | Populated | Reviewed), grade
documents: []
# [W] append-only, newest last: at, grade, by, notes
reviews: []
# [W] every question and answer of building the KB (Feature 002 shape)
qa: []
```

- **`status`**:
  - `Building`: a build is running or waiting.
  - `Approved`: a build ended with the user's approval.
  - `Growing`: a new project's KB, with no build: its skeleton is made by the new-project step, and `/aid-kb-update` adds its documents (see Components, A new project).
  - Setting `Approved` also sets `active_skill: none` and clears `step` / `step_detail` in the same write, as Feature 002's finishing rule does for a work.
- **Dropped from today's file**: the summary status and history (the view has no approval, Q53), the
  external-documentation table (that is `external-sources.md`), the verification spot-checks (evidence
  stays in the build's review ledger) and the calibration log (a console record today).
- **A work's KB changes** go in a new work key. Each `/aid-kb-update` run in a work appends one entry
  at its finish:

  ```yaml
  # [W] append-only, newest last; one entry per KB change made in this work
  kb_updates:
    - at: '2026-10-20T10:00:00Z'
      mode: change
      docs: 'technology-stack.md, architecture.md'
      grade: A
      commit: 1a2b3c4
  ```

  `mode` is `change`, `sweep` or `refresh`. `docs` is one comma-separated string. Both dashboard readers
  accept the key, which they do not display.
- **The work's parent branch** (Q60). Features 001 and 002 have no key for it, so this feature adds
  `pipeline.parent_branch`. It is written once by the gate's `--create --parent-branch <branch>` (`--`
  without git) and never changed. It records the branch the work's worktree was made from: the main
  folder's current branch, which is also the work's pull-request target. Resume and Features 007 and 008
  read it from there.

**Writer modes** -- `writeback-state.sh` keeps Feature 002's lock, quoting, atomic-rename and exit codes.
- **`--kb` target**: points `--step`, `--ask`, `--answer`, `--check` and `--repair` at
  `.aid/knowledge/STATE.yml`. `--step --kb` accepts only `--skill aid-kb-build` and sets
  `status: Building` in the same write, so a saved step never sits on a finished KB.
- **Only two writes create the file** (from `kb-state-template.yml`, in the same write that sets
  `status`): `--step --kb` (the build's START) and `--kb --field Status --value Growing` (the
  new-project step, Components, A new project). Every other `--kb` write on a missing file changes
  nothing and exits 10 (no KB), a new code documented in the writer's header. So no question, gap or
  review ever makes a KB appear.
- **KB-only modes**:

| Mode | Writes |
|---|---|
| `--kb --field F --value V` | F is `Status` (`Building`, `Approved`, `Growing`), `Grade` (`[A-F][+-]?` or `Pending`), `User Approved` (`yes`, `no`), `Baseline` (a commit or `--`), `Domain`, `Triage`, `Elicitation` (`yes`, `no`); any other field or value exits 4 |
| `--kb --doc D --doc-status S [--grade G]` | adds or updates the `documents` entry of D |
| `--kb --review --grade G --notes T` | appends a `reviews` entry: `at`, `grade`, `by` (the saved skill), `notes` |
| `--kb --clear-build` | a confirmed rebuild's reset: every key back to its template value except `status`, the record (`active_skill`, `step`, `step_detail`) and `qa` |
| `--kb-update-log --mode M --docs D --grade G --commit C` | appends a `kb_updates` entry to the work's `STATE.yml`; with `--mode refresh`, `--docs` and `--grade` are not taken and are written `--` (exit 5 when another mode lacks them) |

`--check --kb` reports a missing or inconsistent build record with the work rules applied to the KB record:
- a `Building` file with `active_skill: none` or with `step: --`;
- an `Approved` or `Growing` file that still names a skill.

It exits 9 on any problem. `summarize/writeback-state.sh` and its scalars (`kb_status`, `kb_grade`,
`last_kb_review`, `summary_approved`, `last_summary`) go.

##### 3. Flows

**When the agent runs each skill on its own** (FR-2, FR-8, AC-15). The user never needs to type one.

| Moment | What runs |
|---|---|
| A question about the project | `/aid-kb-query` (Feature 001's flow, step 2) |
| Existing code, no KB, before a work's first phase | `/aid-kb-build`, offered first (Feature 001) |
| The user states a fact about the project ("we moved to Postgres") | A knowledge-update work running `/aid-kb-update` (Feature 001's routing) |
| A decision the user approved changes a project-wide fact | `/aid-kb-update` called inside that work (Feature 005 provides the call) |
| A task built something the KB describes | `/aid-kb-update` called inside that work (Feature 007 provides the call) |
| An idea draft sent to the KB at brainstorm's FINISH (Q47) | `/aid-kb-update` as that work's pass target (Feature 003) |
| A work starts or resumes and a document it reads may be out of date | One question; on yes, `/aid-kb-update` (sweep) called inside that work (Q57) |

Every row that hands work to `/aid-kb-update` is subject to Components, No KB: one rule.
| The user wants to read what the project knows; a build has just ended | `/aid-kb-show` |

The skill-guide lines carry the same moments (Components).

**`/aid-kb-build`** -- Preparation. It is not a work (Feature 002: Preparation is not a work phase). It
builds in the project's **main folder**, on the branch checked out there (Q55) -- the branch every new
work branches from (Q60), so works see the KB once it is committed. It runs **no effort
check** (FR-15, Q17). Its record is the KB build record (Components). Typing `/aid-kb-build` while a build
is saved resumes it.

| Step | Reference | Worker | Advance |
|---|---|---|---|
| START | `references/start.md` | main conversation | `CHAIN` -> ELICIT |
| ELICIT | `references/elicit.md` | main conversation | `ASK` -> GENERATE |
| GENERATE | `references/generate.md` | `aid-architect` (fans out `aid-researcher` as today) | `CHAIN` -> REVIEW |
| REVIEW | `references/review.md` (brief: `references/reviewer-brief.md`) | `aid-architect` (dispatches the `aid-reviewer` panel, as today) | `CHAIN` -> QUESTIONS when a question is `Pending`; `CHAIN` -> FIX when the grade is below the bar; else `CHAIN` -> APPROVE |
| QUESTIONS | `references/questions.md` | main conversation | `ASK` -> FIX |
| FIX | `references/fix.md` | `aid-architect` (one agent per document, as today) | `CHAIN` -> REVIEW |
| APPROVE | `references/approve.md` | main conversation | `ASK` -> FINISH |
| FINISH | `references/finish.md` | main conversation | `HALT` |

0. **Opening check**, before START is entered, so nothing is written yet:
   - not in plan mode (one line, from today's pre-flight);
   - `recon-classify.sh` decides whether code exists. **A new project** (no code): the agent says in one
     line that the KB will grow as things are decided and built, and stops;
   - **a KB already exists** (`status: Approved` or `Growing`): a rebuild is confirmed with one question
     first, which replaces `--reset`. Like Feature 002's intake questions, its outcome is recorded where
     it lands: the build's record (START entered with `--detail 'rebuild'`), or nothing when the user
     declines.
1. **START** -- its step entry (`--kb --step`) also sets `status: Building` in the same write.
   - **A confirmed rebuild** (`step_detail` is `rebuild`) first clears the generated KB, as `--reset` does
     today, then saves `--detail 'rebuild: cleared'`, so a resume never clears twice. **Cleared**: every
     file under `.aid/knowledge/` but the KB state file (documents, `INDEX.md`, `README.md`, `kb.html`), and in that file
     every key except `status`, the record and `qa` (`--kb --clear-build`). **Kept**: `.aid/connectors/`, `.aid/settings.yml`, and
     the KB questions with their answers. The removals reach git with the build's commit.
   - **Otherwise**, its first action is today's existing-KB check (`state-generate.md` Step 0, moved here):
     documents already on disk are kept, and only missing ones are generated. It runs on every other
     entry to START, fresh or resumed.
   - Then the domain and the document set, as today's steps 0c-0f (their confirmations through the question
   protocol); `Domain` and `Triage` written.
2. **ELICIT** -- external sources and connectors, as today; `Elicitation` is set to `yes` once settled.
3. **GENERATE / REVIEW / FIX** -- today's generation, review panel and fix loop. What changes:
   - every state write goes through `--kb` (`--doc`, `--review`, `--field Grade`);
   - every question goes through `--ask --kb`;
   - no banner, no "run again".
   - Unchanged: the "never assume -- ask" rule and the grade bar (`.aid/settings.yml` `minimum_grade`).
4. **QUESTIONS** -- the `Pending` questions, in the protocol's groups. A question the user skips stays
   open (FR-17 rule 10) but no longer sends REVIEW back here, and it does not block APPROVE: its point
   is written in its document as open -- never as a fact -- and it is offered again at the next
   session's start, through the one route for open KB questions (Components, `/aid-orchestrate`). Answered
   after the KB is `Approved`, it goes in as a known-change `/aid-kb-update`, which rewrites the open
   point in its document.
5. **APPROVE** -- one approval of the whole KB (Q56):
   - the KB is shown in chunks, most important documents first (Feature 002 reviews), with the build's
     small decisions confirmed in the same batch;
   - recorded `--ask --kb --category Approval --covers 'KB build'`, then `--answer --kb`;
   - a change the user asks for reopens as a question and goes back to FIX.
6. **FINISH**, after the yes:
   1. stamp `approved_at_commit:` in every document of the set with the current `HEAD`;
   2. regenerate `INDEX.md` and `README.md`'s completeness rows;
   3. render the view;
   4. write `User Approved` `yes` and `Baseline` (the same `HEAD`); the record stays at FINISH;
   5. commit once with `kb-commit.sh --build --finish`. **Nothing is pushed**; the agent says in one line
      how to push. `--finish` makes the commit carry the finished state file: after `git add`, the
      script runs `writeback-state.sh --kb --field Status --value Approved` (which clears the record)
      and stages the state file, then commits. If the commit does not complete, the script puts back the
      copy of the state file it took before that write, so the record is back at FINISH, and exits 6 (the commit
      failed; a new code). The KB is marked `Approved` only by a commit that succeeded, and no clone
      ever receives a KB state file still waiting at FINISH.
   - Without git: nothing is committed, the agent says so, and `Status` `Approved` is written directly.
   - A commit that fails: the agent says why in one line. The build stays at FINISH with its record
     kept and the approved content on disk, so the next resume retries the commit (the approval is
     not asked again: `user_approved` is already `yes`).

**`/aid-kb-update`** -- the only writer of KB documents after a build. It always runs **inside a work**:
- **as the work's own job**: a knowledge-update work the gate creates with `--create --reading 'knowledge
  update' --skill aid-kb-update --step START`, no phase; or a brainstorm work passed to it (Feature 003);
- **called** by another skill with `CALL`, returning to the caller's step.

Its questions go in the work's `qa`; its process state is the work record.

| Step | Reference | Worker | Advance |
|---|---|---|---|
| START | `references/start.md` | main conversation | `CHAIN` -> ANALYZE; `refresh`: `CHAIN` -> CONFIRM |
| ANALYZE | `references/analyze.md` (`references/sweep.md` for a sweep) | `aid-researcher` (clean context) | `CHAIN` -> SCOPE; `ASK` -> ANALYZE when a point cannot be grounded |
| SCOPE | `references/scope.md` | `aid-architect` (clean context) | `CHAIN` -> CONFIRM; `HALT` when nothing needs to change |
| CONFIRM | `references/confirm.md` | main conversation | own job: `ASK` -> APPLY; called: `CHAIN` -> APPLY; `refresh`: on to FINISH the same way |
| APPLY | `references/apply.md` (`references/new-document.md` for a new document) | inline, or `aid-tech-writer` per document | `CHAIN` -> REVIEW |
| REVIEW | `references/review.md` (brief: `references/reviewer-brief.md`) | `aid-reviewer` | `CHAIN` -> APPLY to fix (bounded to the scope); else `CHAIN` -> FINISH |
| FINISH | `references/finish.md` | main conversation | own job: `ASK`, then `PASS` to the close; called: `HALT` (returns) |

1. **START** -- reads the work record: the request or the caller's `why`, and the work's idea draft or
   `draft` sources, each resolved with `idea-drafts.sh path` (Feature 003).
   - **Mode**: `change` (a known change), `sweep` (documents named by the drift check, or "check the KB
     against the code"), or `refresh` (only the index and the view; see `/aid-kb-show`).
   - **`refresh`** changes no document: it goes from CONFIRM straight to FINISH, which skips the
     stamping and writes `--kb-update-log --mode refresh --commit C` with no docs and no grade (both
     `--`).
   - **No KB** (no KB state file at `Approved` or `Growing`): START creates nothing and writes nothing.
     Components, No KB: one rule, keeps every caller away from this case, so this is only a safety net.
     - **Called**: it `HALT`s and returns.
     - **On its own job**: if the work's base commit held a KB (`.aid/knowledge/STATE.yml` exists at the
       merge base of the work's branch and `pipeline.parent_branch`), the agent says the KB was removed
       since the work began, and offers to cancel the work. Otherwise it says the KB is not built yet,
       keeps the work's draft as it is, and offers the build, as that rule says for brainstorm.
2. **ANALYZE / SCOPE**:
   - today's analysis and scope plan: the documents and sections the change lands in, and what is
     deliberately left alone;
   - for a sweep, `kb-freshness-check.sh` names the drifted sources, and a document written from a
     decision is compared with what was built (today's conformance check: divergences are raised, never
     overwritten).
   - A point the code cannot settle is asked (question protocol). During Building such a question is a
     real blocker (FR-6) only when the change cannot go on without it. Otherwise it is recorded and asked
     at the next milestone, and the point stays out of the KB until answered.
3. **CONFIRM**:
   - **own job**: the confirmation before editing, shown with the scope (one short line in `lite`) -- the
     approvals table row (Components);
   - **called**: no stop. The scope is saved in `step_detail` and shown with the work's next approval.
4. **APPLY** -- edits within the confirmed scope only. In a new project the skeleton already exists, so
   APPLY only adds and changes documents. A fact whose document does not exist yet:
   `new-document.md` creates the document from `knowledge-base/<doc>.md` when a template exists, or
   else with the fields `kb-authoring/frontmatter-schema.md` requires. It registers the document in
   `.aid/settings.yml` `knowledge.doc_set` and in `README.md`, choosing the document by the concern model
   (`kb-authoring/concern-model.md`) -- the job the retiring `create` skills did.
5. **REVIEW** -- one graded review **scoped to the changed documents** (Q58):
   - today's panel minus its whole-KB teach-back exit;
   - the scope-diff guard first, then grade, act-back and teach-back on the changed documents;
   - the bar is `minimum_grade`;
   - the ledger is `.aid/.temp/review-pending/<work>-kb-update.md`.
   It runs in every mode except `refresh`.
6. **FINISH**:
   1. stamp `approved_at_commit:` in each changed document with the current `HEAD`;
   2. regenerate `INDEX.md`;
   3. render the view;
   4. commit with `kb-commit.sh` on the work's branch;
   5. `--kb-update-log`.
   - **Called**:
     - one `qa` entry, `category: KB change`, recorded `Assumed` (`--ask` then `--answer --state
       Assumed`), so the next approval confirms it in its batch (Feature 002);
     - then `HALT`, which returns to the caller.
   - **Own job**:
     - the KB change approval (Components), whose yes runs Feature 003's draft deletion;
     - then `PASS` to the close: the close minimum, run by `/aid-orchestrate` until Feature 008.
     - A change the user asks for goes back to SCOPE.

**`/aid-kb-query`** -- one pass, no step table, starts no work (AC-4).
- **Answer**: from the KB, the code and open works, with sources, as today.
- **When the KB lacks what the code shows**: answer from the code (cited), then ask one question offering
  a KB update (recommendation: yes) -- or, with no KB, the build (Components, No KB: one rule). Yes opens a knowledge-update work through `/aid-orchestrate`, or, inside
  a work, a call.
- **When nothing can answer**: say so.
- **Writes**: only the gap record, through `--ask` (in a work: the work's `qa`; otherwise `--ask --kb`),
  `category: Knowledge Base`, `asked_by: aid-kb-query`. Nothing else. Outside any work in a project with
  no KB, it says so and records nothing (the writer would refuse with exit 10 anyway).

**`/aid-kb-show`** -- one pass, builds nothing (FR-2, Q15). It runs `render-kb-view.sh --check`:

| Exit | Says |
|---|---|
| 0 (current) | the link: `file://` plus the absolute path of `kb.html`, and that `aid dashboard start` also shows it |
| 1 (older than the KB) | the link, that the view is older than the KB, and one question offering a refresh (recommendation: yes); yes runs `/aid-kb-update` in `refresh` mode -- called inside the current work, or as a knowledge-update work |
| 3 (missing) | with a KB that holds documents: that there is no view yet, and the same refresh question; with a `Growing` KB that holds no document: "Nothing is recorded in the KB yet; it grows as things are decided and built" -- nothing offered, no work started; with no KB: that the KB is built or grows first |

##### 4. The view

`render-kb-view.sh` makes `kb.html` from the KB documents alone, **with no agent and no user step** (Q53).
- **Only on a KB with documents**: every caller renders only when the KB holds at least one document, so
  exit 4 is a guard, never a path. `/aid-kb-update` FINISH skips the render (and leaves `kb.html` as it
  is) when the KB holds none; `/aid-kb-show` never offers a refresh then.
- **When it runs**: `/aid-kb-build` FINISH and every `/aid-kb-update` FINISH. **Nothing else writes the
  file**, with one named exception: Feature 008's step that resolves a pull-request collision on `kb.html`
  or `INDEX.md` runs `render-kb-view.sh` and `build-kb-index.sh`, stages both files, and finishes the merge
  with its own normal merge commit (What other features must provide).
- **Git**: the view is tracked in git (Q54). A merge collision on it, or on `INDEX.md`, is resolved by
  rendering again, never by hand.

| Use | Does |
|---|---|
| `render-kb-view.sh [--root DIR] [--settings FILE] [--output FILE]` | Renders (defaults `.aid/knowledge`, `.aid/settings.yml`, `<root>/kb.html`) into a temporary file renamed into place; exit 2 bad argument, 4 no KB document, 5 a template missing |
| `render-kb-view.sh --check [--root DIR]` | Writes nothing; exit 0 current, 1 stale (the stored input hash differs or is absent), 3 no `kb.html` |

- **Inputs, in order**:
  - the document set (`knowledge.doc_set` through `read-setting.sh`) as found on disk, then any other
    `.aid/knowledge/*.md` alphabetically, so no document is hidden;
  - `INDEX.md` and `README.md` are not sections;
  - the KB state file is not read;
  - the templates kept in `knowledge-summary/`, and the project's `name` and `description` from
    `.aid/settings.yml`.
- **Page**:
  - `html-skeleton.html` (language, landmarks, skip link, light/dark switch), with `component-css.css`
    and `lightbox.js` inlined. No external fetch, no diagram engine.
  - "At a Glance" first, from `capability-inventory.md`'s `summary:` and its first rows, the first
    `domain-glossary.md` terms and the first `decisions.md` titles, each part only when its document exists.
  - Then the glossary, decision and capability cards (today's anchors: `glossary`, `decisions`,
    `capabilities`, and per item `gloss-<slug>`, `adr-d<N>`, `cap-<slug>`), each parsed from its
    document's headings and rows. A document that does not match that structure renders as an ordinary
    section.
  - Then primary, extension and meta documents in set order, then an index of every document.
  - Each section: the document's H1, its `summary:` as the plain-language lead, `objective:`, `tags:`
    pills, `see_also:` links, the body, and a source line linking `./<doc>.md`.
  - The documents' text, frontmatter stripped, is embedded for the page's Markdown export, base64 in
    `<script type="text/markdown" id="kb-md-export">`.
- **Markdown read**:
  - Rendered: headings, paragraphs, bullet and numbered lists (nested by indent), pipe tables, fenced
    code, block quotes, inline code, bold, italic and links. A link to another rendered document points
    at its section.
  - Every character is HTML-escaped first; anything else shows as plain text. No hand-drawn visual is
    made: KB documents carry no diagrams (D18).
- **Same KB, same bytes**:
  - no date or time, no absolute path, no random id, fixed order, `LF`, `LC_ALL=C`;
  - `<meta name="aid-kb-inputs" content="sha256:<hex>">` is the hash of every input's path and bytes plus
    the renderer's version line; `--check` recomputes it.
- **Dependencies**: bash, awk, sed, `base64`, and `sha256sum` or `shasum` -- no Python, no Node, as
  `build-kb-index.sh`.
- **`build-kb-index.sh`** drops its embedded timestamps (the `AUTO-GENERATED` comment's time and the
  `Generated at:` line), so the same documents give the same `INDEX.md` (tech-debt W4-5) and parallel
  branches stop colliding on it.

##### 5. Components

**Descriptions and skill-guide lines** (Feature 001's shape; final text set at build):

| Skill | `description:` | Skill-guide line |
|---|---|---|
| `/aid-kb-build` | "Build the Knowledge Base from a project's existing code, asking what it cannot confirm, and end with one approval. Use when a project with code has no Knowledge Base, or the user asks to rebuild it." | `` - `/aid-kb-build` -- build the Knowledge Base from existing code; when code has no Knowledge Base `` |
| `/aid-kb-query` | "Answer a question about this project from the Knowledge Base, the code and open works, with sources. Use when the user asks how something works, where it is, or what was decided." | `` - `/aid-kb-query` -- answer a question about the project from the Knowledge Base, with sources `` |
| `/aid-kb-update` | "Record a decided or built fact in the Knowledge Base, or fix documents that drifted from the code, then refresh its web view. Use when a decision is approved, a task changes what the KB describes, the user states a fact, or a document is out of date." | `` - `/aid-kb-update` -- record a decided or built fact, or fix drift; when the project changes `` |
| `/aid-kb-show` | "Give the link to the Knowledge Base web view and say whether it is current. Use when the user wants to read what the project knows." | `` - `/aid-kb-show` -- give the link to the Knowledge Base web view; when the user wants to read it `` |

Each guide line is within SG-03's limit. `## Handling a request` keeps its line count: its Preparation
bullet already says the KB is built once and then updated on demand.

**Rules text** (`canonical/aid/rules.md`):
- the tracking line names `.aid/knowledge/STATE.yml` for KB state;
- the connectors line says connectors are catalogued "when `/aid-kb-build` builds the Knowledge Base"
  (today: `aid-discover` (ELICIT)).

Both lines stay within `test-shared-layout-sources.sh`'s constraints: no tool folder, no `canonical/` path.

**The KB build record** -- a new section of `skill-steps.md`, after § The work record:
- **Its place**: `/aid-kb-build` is the only skill that runs outside a work. Its `active_skill`, `step`
  and `step_detail` live in the KB state file, written with `--kb --step`.
- **Its rules**: every rule of § The work record applies unchanged:
  - written at step entry before any work;
  - fail-closed;
  - only the writer touches it;
  - resume from it alone;
  - `--check --kb`, then one confirmed `--repair --kb`, on every resume.
- **Its reach**: it decides only where a build resumes. A work's record never names `aid-kb-build`, and
  the KB record never names a work: no hand-off links them. The build is offered before a work starts,
  and that work starts after the build ends.
- This adds a second record without changing who decides where a work resumes. `test-skill-steps.sh`
  SS-14 (b) adds `kb-state-template.yml` to its list of template exceptions.

**Approvals** -- `skill-steps.md` § When approvals happen gains two rows. These are the rows Feature 003
asked for:

| Moment | `full` | `lite` |
|---|---|---|
| Confirmation before the KB is edited -- a knowledge-update work's CONFIRM | approve | approve |
| The KB change -- a knowledge-update work's result, recorded `category: Approval`, `covers: KB change` | approve | approve |

- **Coinciding approvals**: on a knowledge-update work the KB change approval and the final-result
  approval fall at the same moment, so they are one approval (M11). Feature 003's deletion rule fires on it.
- **KB changes made by a call inside another work** have no row of their own. They are small decisions,
  confirmed in the batch of the work's next approval (Feature 002, Q36). A rejected one reopens as a
  question, and the agent changes the KB again by another call.
- **The build's approval** is not a work approval. It stays in the KB state file (Flows).

**`/aid-orchestrate`** (Feature 001's references):

- **`start-or-resume.md`** gains two steps:
  - **The build first.** When the KB state file shows `status: Building` with a saved step, the agent
    first offers to finish that build (one question, recommendation: yes) and resumes it on yes.
  - **Open KB questions** -- the one route, whatever the KB's `status`. At session start, the open entries
    (`Pending`, `Skipped`) of the KB state file are offered in their groups, like a work's (FR-17 rule 10).
    The answer is recorded (`--answer --kb`), then applied by status:
    - `Building`: the build uses it at its next step;
    - `Approved` or `Growing`: a known-change `/aid-kb-update` rewrites the open point in its document --
      called inside the current work, or as a knowledge-update work when there is none.
  - **The drift check** (Q57), after the work's open questions and before its first new question:
    - **What runs**: `kb-freshness-check.sh --doc <doc> --format tsv` for each KB document
      `check-intent.md` read for this request.
    - **A `suspect` row**: one question, `category: Knowledge Base`, importance medium. "These Knowledge
      Base documents may be out of date: <doc> (<changed sources>). Update them as part of this work?"
      Recommendation: yes.
    - **Yes**: `--handoff --to aid-kb-update --step START --why 'KB drift: <docs>' --returns yes`, and the
      update runs in `sweep` mode and returns to the work's step. The fix rides the current work and is
      shown at its next approval (Q59), like any KB change made by a call.
    - **No**: the answer is recorded, and the same documents are not raised again in this work.
    - **`current` or `unknown`**: nothing is said.
    - **Skipped** with no KB (Components, No KB: one rule) or no git.
- **`size-and-route.md`**: the "Knowledge update" row creates the work with `--skill aid-kb-update --step
  START` and no phase; the Preparation row names `/aid-kb-build`. **Before that `--create`**, it checks for
  a KB by the same rule as everywhere else: a KB exists only when the main folder's
  `.aid/knowledge/STATE.yml` says `Approved` or `Growing`. As with Feature 002's intake questions, what it
  asks here is not written with `--ask`, because no work exists yet:
  - **No KB, a project with code** (no state file): the build is offered first.
  - **A first build not finished** (`Building`): finishing that build is offered first.
  - In both cases the update work is created only after the build's commit. Its branch is made from the
    main folder's current branch (Q60), which holds that commit, so it contains the KB. If the user declines, no work is created.
  - **A new project** (no state file, no code): the work is created as now; the gate's § 3a runs the
    new-project step before the worktree, so the work's branch holds the `Growing` KB.

  One new row:

  | Reading | Phases |
  |---|---|
  | A new project (no code, no KB) | no Preparation: the gate's new-project step (A new project) commits the KB skeleton, and the KB grows through `/aid-kb-update` as things are decided or built |

- **`feedback-routing.md`**: "KB questions -> KB update" names `/aid-kb-update`.

**No KB: one rule.** A KB exists only when the KB state file says `Approved` or `Growing`. A new
project always has one before its first work (A new project, below). In a project with code and no KB,
no path hands work to `/aid-kb-update` expecting a KB. Every caller checks first:

| Caller | With no KB |
|---|---|
| Brainstorm's FINISH (Feature 003) | Offers "build the KB first" in place of "KB update". The idea is kept as a draft (Feature 003's *Keep it as a draft*: loose in the main folder, the work cancelled), and the build is offered. After the build's commit, the agent offers to take the draft to the KB: a knowledge-update work created then, through the gate, with the draft as a `draft` source, deleted at that work's KB change approval as Feature 003's rule does for a draft handed to a KB update |
| `size-and-route.md`'s knowledge-update row | Offers the build first (above) |
| The drift check | Skipped |
| A decision approved inside a work (Feature 005) and the Building call (Feature 007) | No call. The agent says once per work that the KB is not built, so this fact will be recorded when it is |
| The open KB questions route | Nothing to offer |
| `/aid-kb-query`'s update offer | Offers the build instead |
| `/aid-kb-show`'s refresh | Never offered without documents (its table) |

**A new project (FR-10, AC-18).**
- **The new-project step** sits on the one path every work goes through: the gate's § 3a (Feature 002),
  which a plain request, a typed slash command and a doorway skill all use. Before § 3a creates a work's
  worktree in a project with no KB state file and no code (`recon-classify.sh`), it works in the main
  folder:
  - sets `type: greenfield` in `.aid/settings.yml` (the key `/aid-config` already sets);
  - makes the KB skeleton: the KB state file at `Growing` (`--kb --field Status --value Growing`), and a
    `README.md` with an empty completeness table and an `INDEX.md` from `build-kb-index.sh`, both holding
    no document;
  - commits them with the settings file in one `kb-commit.sh --new-project` commit; nothing is pushed.
  - Every work then branches from the main folder's current branch (Q60), at a commit that already has
    the KB state file. Two works never both
    create it, and the state file, `README.md` and `INDEX.md` are never created twice. A collision on
    `INDEX.md` or `kb.html` from two works adding documents is resolved by Feature 008's re-render step.
  - A project with code and no KB gets the build instead (Feature 001), even when the user declines it
    for now. Without git, the skeleton is made in place and nothing is committed.
- **No facts up front**: no build runs, and the skeleton holds no document until the first fact. The first
  `/aid-kb-update` adds the document that fact belongs to.
- **When a fact enters** (decision D28's commitment line):

| A fact enters when | Where |
|---|---|
| the user approves a decision (a requirements approval, an answer that settles a project-wide choice, an idea draft sent to the KB) | `decisions.md`; the chosen stack in `technology-stack.md`; `roadmap.md` / `backlog.md` |
| the part it describes is built and verified | `architecture.md`, `module-map.md`, `project-structure.md`, `test-landscape.md`, `integration-map.md`, `infrastructure.md`, `capability-inventory.md`, `domain-glossary.md` |

- **The rule**: a decision is recorded as a decision once approved. A description of the system is
  written when that part exists. Nothing is written up front.

**Roadmap, backlog and MVP (FR-14, AC-39)**:
- **Ordinary documents**: they are ordinary KB documents written by `/aid-kb-update`, from the two new
  templates. The MVP is roadmap.md's `## MVP` section (Q16).
- **How ideas reach them**: only when the user chooses "KB update" at brainstorm's FINISH (Q47). The kind
  catalog's `then` is only its recommendation.
- **"Work on the next backlog item"**: `check-intent.md` reads `backlog.md`, names the top item in the
  agent's one-line reading, and records `backlog.md` as a work source (Feature 001's `sources:`, kind
  `document`). When the work is built, the item is updated as `backlog.md` says (What other features
  must provide).
- **No skill is dedicated to them.**

**`kb-commit.sh`** -- the only code that commits KB paths:

| Use | Commits |
|---|---|
| `kb-commit.sh --new-project --message M` | `.aid/settings.yml` and `.aid/knowledge/` (the new-project step's key and KB skeleton, Components, A new project) |
| `kb-commit.sh --message M [--with-settings]` | `.aid/knowledge/` (additions, changes and removals), plus `.aid/settings.yml` when `--with-settings` (passed when this run registered a document or changed the document set) |
| `kb-commit.sh --build [--finish] --message M` | the same, plus `.aid/connectors/` and `.aid/settings.yml`; `--finish` marks the KB `Approved` inside the commit, as the build's FINISH says |

- **How**: `git add -- <paths>`, then `git commit --only -- <paths>`. Other staged files stay staged and
  uncommitted.
- **Exit codes**: 0 committed (or nothing to commit, said in one line); 2 bad argument; 3 no git; 6 the
  commit failed after staging (with `--finish`, the state file is put back); 4 the
  branch cannot take a commit (none checked out, a merge or rebase in progress).
- **No push, ever.**

**Dashboard** (both readers, kept equal by the parity tests):
- **What they read**: `.aid/knowledge/STATE.yml` through the state reader. A project whose KB state is
  still `STATE.md` is read by today's parse, moved inside a block marked `legacy-kb-state: begin` /
  `end`. That parse reads the KB approval line, not the summary's.
- **KB state passed on**:
  - `kb_status`, `kb_grade` and `last_kb_review` come from `status`, `grade` and the newest `reviews` entry;
  - new: `approved`, `step` and `open_questions` (`Pending` + `Skipped`);
  - `summary_present` stays;
  - `summary_approved`, `last_summary_date`, the KB `source_mode` and `kb_baseline` go.
  - `server.py` and `server.mjs` pass the new fields to the page.
- **KB status, first match wins**:
  1. no `.aid/knowledge/`, an empty one, or a `Growing` skeleton with no document yet -> `pending`;
  2. `status: Building`, or `Approved` without `user_approved: 'yes'` -> `generating`;
  3. no `kb.html` -> `preparing`;
  4. any document `suspect` by the per-document check the readers already run -> `outdated`;
  5. else `approved`.
  - `Growing` follows steps 3-5. The branch-tip comparison against `knowledge.last_update` goes, with
    `git_freshness_check` / its Node twin and `parse_kb_baseline` (tech-debt L6).
- **The KB card** (`home.html`) names no skill:
  - pending: "Ask your AI tool to build the Knowledge Base", or, for a `Growing` skeleton, "The Knowledge Base grows as things are decided and built";
  - generating: "The Knowledge Base is being built", plus "Waiting for your answer (N)" when questions are open;
  - preparing: "Approved -- the web view is not rendered yet";
  - ready: the document count;
  - outdated: "Some documents may be out of date; the agent offers an update when a work starts".

##### 6. What other features must provide

| Feature | Must provide | Waiting on it |
|---|---|---|
| 005 | After the `REQUIREMENTS.md` approval, one `CALL` to `/aid-kb-update` (`change`) carrying every approved decision that settles a project-wide fact (one call per approval, Q68), only when a KB exists (Components, No KB: one rule) | `004-10` |
| 006 | Its work-state conversion joins format 6 (Migration) | -- |
| 007 | Its per-delivery branches are gone, and the work's one branch is compared against `pipeline.parent_branch` (Q60), never against `master`. After each task is verified and committed, the KB check: `kb-freshness-check.sh` over the documents whose `sources:` the task touched, plus the task's own report of a new module, dependency or convention; on a hit, and only when a KB exists (Components, No KB: one rule), a `CALL` to `/aid-kb-update`, which stamps against that commit. At the end of the whole build, the same for the backlog or roadmap items the work's `sources:` name. The milestone approval lists the work's `kb_updates` | `002-13`, `004-11`, `004-12` |
| 008 | The pull request targets `pipeline.parent_branch` (Q60), and the close compares against it, never against a hard-coded `master`. The close of a work takes over `cleanup-classify.sh` (housekeep's clean-up of finished works, with tech-debt SY-1). A pull-request collision on `kb.html` or `INDEX.md` is resolved by running `render-kb-view.sh` and `build-kb-index.sh`, staging both files and finishing the merge with Feature 008's own normal merge commit, never by hand -- the named exception in The view and KB-03 | -- |
| 009 | Its single catalog brings back no `create` / `update` kind for a KB document | -- |

##### 7. Migration

| Old | New |
|---|---|
| `/aid-discover` | Say what you want; the agent offers `/aid-kb-build` when the code has no Knowledge Base |
| `/aid-ask` | Ask the question in plain words (`/aid-kb-query`) |
| `/aid-update-kb` | Tell the agent what changed (`/aid-kb-update`) |
| `/aid-summarize` | Nothing to run: every KB build and update renders `kb.html`; `/aid-kb-show` gives the link |
| `/aid-housekeep` | Drift is checked when a work starts and fixed by `/aid-kb-update`; finished works are cleaned up when they close |
| `/aid-create-` / `/aid-update-` `architecture`, `stack`, `testing-strategy`, `cicd` | Tell the agent the decision or change (`/aid-kb-update`); a new project's KB records them as they are decided or built |
| `/aid-create-` / `/aid-update-` `roadmap`, `backlog`, `mvp` | Talk it through with `/aid-brainstorm` and choose "KB update", or tell the agent the change |

- **Release notes**: the rows join the old -> new table (AC-24), drafted in `.aid/knowledge/backlog.md`
  § Next Release. No stubs (M1).
- **Installed projects**: `aid update` removes the retired skills, scripts and templates through the
  install manifest (decisions.md § D9).
  - Leftover `aid/update-kb-*` and `aid/housekeep-*` branches and worktrees are left for the user: nothing
    here can tell whether their unmerged commits are still wanted.
  - Leftover `.aid/.temp/` run files go with that folder's own clean-up.
- **Format 6** -- v4's one layout bump for state (decisions.md § D13):
  - **The carriers**: this feature raises `AID_SUPPORTED_FORMAT` to 6 in all its carriers (`bin/aid`,
    `bin/aid.ps1` `AidSupportedFormat`, `lib/AidInstallCore.psm1`, `lib/aid-install-core.sh`'s default,
    the settings template).
  - **The conversion step**: `_aid_migrate_repo`'s CONVERT-STATE step and its PowerShell twin gain the KB
    step below. Feature 006 adds its work-state step to the **same** format 6, so there is no format 7.
  - **Era markers**: STEP 0 DETECT accepts `.aid/knowledge/STATE.yml` as well as today's markers.
  - **Twins**: bash and PowerShell give byte-identical output, are PowerShell 5.1-safe and ASCII.
  - **The KB step**, run when `.aid/knowledge/STATE.md` exists and `STATE.yml` does not:
    - frontmatter scalars:
      - `kb_status` becomes `status`. `Approved` stays; anything else becomes `Building`, with
        `active_skill: aid-kb-build` and `step: START`. A resume enters START, whose first action is the
        existing-KB check (Flows): the documents already written are kept and only missing ones generated;
      - `kb_grade` becomes `grade`;
      - the approval line becomes `user_approved`;
    - sections:
      - `## Discovery Domain` (`Confirmed` value) becomes `domain`;
      - `## Discovery Triage` (`Path`) becomes `triage`;
      - `## Discovery Elicitation` (`Resolved`) becomes `elicitation`;
      - `## KB Documents Status` rows become `documents`;
      - `## Review History` rows become `reviews`;
      - each `### Q<N>` of `## Q&A (Pending)` becomes a `qa` entry (`Required` impact becomes `High`);
    - for an `Approved` KB, `active_skill: none` and `step: --`;
    - the summary sections, spot-checks and calibration log are dropped;
    - `STATE.yml` is written and `STATE.md` deleted;
    - running it again changes nothing.
  - **Baselines** (Q57): every hand-authored primary or extension document without `approved_at_commit:`
    gets `git log -1 --format=%H -- <doc>`. With no git, or a document never committed, the field is
    left absent (the check reports `unknown`). A document that already carries the field is not touched.
  - **Parent branch** (Q60): every existing work's `STATE.yml` -- in the main folder and in each worktree
    `git worktree list` registers -- that has no `pipeline.parent_branch`, or has it empty, gets the
    branch old works were made from, today's default:
    - `master` when a local `master` exists;
    - otherwise the main folder's current branch;
    - `--` with no git.
    A value already there is not touched, so a re-run changes nothing. Bash and PowerShell give the same
    output.
- **Existing works**: `work-initiation-gate.md` § 3b legacy block gains one row. A work whose
  `pipeline.initiator` is a deleted `create` / `update` KB skill is proposed `/aid-kb-update` at START,
  `change` mode. Its old seed is found and collected with `idea-drafts.sh list` / `collect` (Feature 003)
  and read as the work's draft. Feature 006's migration uses the same row.
- **This repository**: its KB state file is converted by running the migration, and its `kb.html` is
  re-rendered by the script.
- **Re-pointing** -- one rule: every kept file under `canonical/`, and `dashboard/home.html`, that names a
  retired skill (`aid-discover`, `aid-ask`, `aid-update-kb`, `aid-summarize`, `aid-housekeep`, the KB
  `create` / `update` skills), a moved reference by its old path (`aid-discover/references/...`,
  `aid-update-kb/references/...`, `aid-ask/`), or `.aid/knowledge/STATE.md`, is re-pointed to its new
  home: the skill that now does the job, the reference's new path, or `.aid/knowledge/STATE.yml`. A
  descriptive mention is reworded. The moved references are under the same rule. Exempt: the gate's
  legacy block (old works' initiators) and `canonical/aid/scripts/migrate/` (it reads old shapes). KB-02
  and KB-04 enforce the rule. Pointers that need a target, not only a new name:
  - `connectors/reconcile.md` and `connectors/preset-catalog.md` -> `aid-kb-build/references/elicit.md`
    (the build's ELICIT step, Step E2);
  - `kb-authoring/concern-model.md`, `domain-doc-matrix.md`, `frontmatter-schema.md`, `review-rubric.md`
    and `principles.md` -> `.agents/skills/aid-kb-build/references/doc-set-resolve.md`,
    `document-expectations.md` and `review.md`;
  - `knowledge-summary/html-skeleton.html`: its `description` and `generator` meta and its footer ("Re-run
    /aid-summarize") say the page is rendered by `render-kb-view.sh` from `.aid/knowledge/`, with no command
    to run; `lightbox.js`'s header names the renderer;
  - the escalation lines of `aid-architect`, `aid-researcher` and `aid-reviewer` record through `--ask`
    (the work's `qa` in a work, `--ask --kb` otherwise; outside a work with no KB, the question goes in
    the agent's report only);
  - `aid-execute`'s "kb-gap -> targeted /aid-discover" -> a `CALL` to `/aid-kb-update`;
  - `dashboard/home.html`'s KB card texts (Dashboard);
  - the `GENERATED` doorway skills change through their builder.
- **Site** (outside `canonical/`, so outside the rule): `site/scripts/skills/` (roster, groups, counts), `site/scripts/.skills-manifest.json`,
  `site/scripts/gen-reference.mjs`, `site/scripts/lib/flow-graph/advance.mjs` and
  `extract-dispatch.mjs`, with their `__tests__`; pages and flows regenerated by
  `site/scripts/gen-skills.mjs`.
- **Lists other features own** -- each changes in the same commit as the skill it concerns, or their
  tests fail:
  - **Shared exempt list** (`tests/canonical/skill-steps-exempt.tsv`): every row with owner Feature 004
    goes (the deleted `create` / `update` KB skills and `design-lifecycle.md`).
  - **Never-merges test** (`tests/canonical/test-never-merges.sh`): NM-03's `aid-housekeep` exemption
    goes.
  - **Description exempt list** (`test-skill-guide.sh` SG-04): the rows of every retired skill go. The
    four KB skills are not exempt.
  - **Skill guide**: it matches `canonical/skills/` both ways (SG-02).
  - **Deferred list** (`tests/conversation/deferred.tsv`):
    - the `skill:` rows for `aid-discover`, `aid-ask`, `aid-update-kb`, `aid-summarize`,
      `aid-housekeep` and the KB `create` / `update` skills go;
    - `003-11` runs now;
    - `002-13` waits only for Feature 007;
    - Feature 004's deferred samples are added.
  - **SS-13** finds the moved and the new `reviewer-brief.md` by its glob.
- **Retired suites** -- each moves to `tests/coverage-accepted-removals.tsv`:
  - **Summarize**: `test-grade-summary.sh`, `test-guardrails-d012.sh`, `test-visual-fidelity.sh`,
    `test-validator-behavior.sh`, `test-summarize-preflight.sh`, `test-assemble-3part.sh`,
    `test-assemble-3part-ps1.sh`, `test-assemble-determinism.sh`, `test-diagram-content.sh`,
    `test-kb-export.sh`, `test-kb-export-pw.mjs`, `test-md-export-embed.sh`,
    `test-kb-html-claims-check.sh` (tech-debt SY-7: the view can no longer drift from the KB),
    `test-payload-size.sh` and `test-contrast-check.sh` (replaced in Testing).
  - **Housekeep**: `test-housekeep-branch-commit.sh` and `test-housekeep-state.sh`.
- **Re-pointed suites**:
  - `test-update-kb-scope-fidelity.sh`, `test-conformance-lane-semantics.sh` and
    `test-f010-governance-guards.sh` follow their text into `aid-kb-update`.
  - The housekeep classify, deletion-split and work-folder-safety suites stay with `cleanup-classify.sh`.
  - The suites naming `aid-discover` or `knowledge/STATE.md` change with them (among them
    `test-kb-review-surface.sh`, `test-state-review-surface.sh`, `test-aid-migrate-trigger.sh`,
    `test-artifact-discipline.sh`, `test-connector-set-unset-lifecycle.sh`, `test-dashboard-parity-h.sh`,
    `test-kb-freshness-check.sh`, `test-doc-set-*.sh`, `test-discovery-doc-ownership.sh`,
    `test-cutover-no-dangling.sh`), as do the dashboard KB tests and fixtures (`pt1h-kb-*`, which also
    gain a legacy `STATE.md` fixture).
  - `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv` are re-recorded.
- **User documentation** waits for the final pass (Q40, AC-45). The only edit now: the numbers
  `test-doc-counts.sh` asserts.
- **KB** (no work ids):
  - `architecture.md`, `capability-inventory.md`, `module-map.md`, `pipeline-contracts.md` (Discover ->
    Preparation; the KB loop);
  - `project-structure.md`, `artifact-schemas.md` (the KB state file, `kb_updates`, the view);
  - `domain-glossary.md` (Preparation, KB build, update, query, show, web view, drift; summarize,
    housekeep and the KB `STATE.md` vocabulary go);
  - `quality-gates.md` (the two-grade view rubric goes);
  - `test-landscape.md`, `infrastructure.md`, `integration-map.md`, `technology-stack.md` (Playwright and
    the root `package.json` go);
  - `authoring-conventions.md`:
    - the `state` row of the type registry and criterion G-04 retire, since this was the last in-scope
      `STATE.md`;
    - the resolution example and the count of expressible rows follow;
    - the view exception names the script;
  - `tech-debt.md`:
    - L6, SY-7, W4-5 and the view half of W1-11 resolved;
    - SY-1 moves with `cleanup-classify.sh`;
  - `roadmap.md` § MVP (the delivered roadmap, MVP and backlog skills are retired).
  - `decisions.md` gains "the Knowledge Base keeps itself current: four skills, writes only inside
    works, a script-rendered view". It amends D18 (the view is rendered from the documents, with no
    drawn diagrams) and D28's consequence (`/aid-kb-update`, not a `create` step, turns a decision into
    a KB fact), both marked in the summary table and their sections.
  - Then `INDEX.md` is regenerated and `kb.html` rendered.

##### 8. Testing

Per NFR-T (Q35): unit tests and static checks now; a sample that needs a later feature waits on the
deferred-tests list.

**Static checks -- `tests/canonical/test-kb-skills.sh`** (picked up by `tests/run-all.sh`; added to the
suite list of `.github/workflows/installer-tests.yml`):

| Group | Asserts |
|---|---|
| KB-01 | `aid-kb-build`, `aid-kb-query`, `aid-kb-update`, `aid-kb-show` exist. Absent: `aid-discover`, `aid-ask`, `aid-update-kb`, `aid-summarize`, `aid-housekeep`, the KB `create` / `update` skills, `design-lifecycle.md`, `discovery-state-template.md`, `canonical/aid/scripts/summarize/`. No `shortcut-catalog.yml` row names a retired skill |
| KB-02 | The re-pointing rule (Migration): no kept file under `canonical/`, nor `dashboard/home.html`, names a retired skill or a moved reference by its old path (`aid-discover/`, `aid-update-kb/`, `aid-ask/`, `state-elicit.md`, `state-generate.md`, ...), except the gate's legacy block and `canonical/aid/scripts/migrate/` |
| KB-03 | `aid-kb-show` and `aid-kb-query` have no `Write` or `Edit` in `allowed-tools`. `render-kb-view.sh` (without `--check`), `build-kb-index.sh` and `kb-commit.sh` are run only by files of `aid-kb-build` and `aid-kb-update`, with two named exceptions: files under `canonical/skills/aid-monitor-pipeline/` run the first two for Feature 008's pull-request collision step, and `canonical/aid/templates/work-initiation-gate.md` § 3a runs `build-kb-index.sh` and `kb-commit.sh --new-project` for the new-project step. No file but `kb-commit.sh` runs `git commit` on `.aid/knowledge/`, with one named exception: the merge commit of that same Feature 008 step, which finishes a merge whose `kb.html` / `INDEX.md` collision it re-rendered. `kb-commit.sh` has no `git push` |
| KB-04 | `kb-state-template.yml` parses through the dashboard reader with no warning; nothing under `canonical/` writes `summary_approved`, `kb_baseline`, `## Q&A (Pending)` or `## Summarization History`; under the re-pointing rule, `.aid/knowledge/STATE.md` is named by no kept file under `canonical/`, nor `dashboard/home.html`, outside `canonical/aid/scripts/migrate/`, which must read old shapes |
| KB-05 | `skill-steps.md` has the two approval rows and § The KB build record; `aid-kb-update`'s `finish.md` names `idea-drafts.sh`, `--kb-update-log` and the close |
| KB-06 | `start-or-resume.md` names `kb-freshness-check.sh` and the build's resume offer; `size-and-route.md` routes a knowledge update to `aid-kb-update`; `work-initiation-gate.md` § 3a runs the new-project step (`type: greenfield`, `kb-commit.sh --new-project`) before it creates the worktree; `check-intent.md` names `backlog.md` and records it as a work source |
| KB-07 | `knowledge-base/roadmap.md` has a `## MVP` heading; `knowledge-base/backlog.md` exists |
| KB-08 | `canonical/aid/rules.md` names `.aid/knowledge/STATE.yml` and `/aid-kb-build` in its connectors line |

**Unit tests**
- **`tests/canonical/test-render-kb-view.sh`**, on a fixture KB:
  - rendering twice gives identical bytes, with no date or time;
  - a section per document in the fixed order, with the three card types;
  - a document that matches no card structure still renders;
  - markup in a document is escaped;
  - each Markdown form renders, and an unknown one shows as text;
  - no external link: every `src` and `href` is a fragment, a relative link to a KB document (`./<doc>.md`), or one of the skeleton's own dashboard links (`/`, `./home.html`); none starts with a scheme (`http:`, `https:`, ...) or `//`;
  - landmarks, language and the skip link are present;
  - the contrast of the inlined palette passes `tests/canonical/lib/contrast-check.mjs`;
  - `--check` returns 0, 1 and 3 for its three cases and writes nothing;
  - a missing template exits 5.
- **`tests/canonical/test-build-kb-index.sh`**: rebuilding gives the same `INDEX.md`, with no timestamp line
  (W4-5).
- **`tests/canonical/test-worktree-lifecycle.sh`** (Q60): with the main folder on a branch other than
  `master` and `master` also present, `create` without `--base` makes the worktree from the checked-out
  branch (its first commit is that branch's tip, not `master`'s); with no branch checked out it exits 2
  and creates nothing. `test-writeback-state.sh` checks that `--create --parent-branch` writes
  `pipeline.parent_branch`.
- **`tests/canonical/test-kb-commit.sh`**, on throwaway git fixtures:
  - only KB paths are committed;
  - another staged file stays staged;
  - `--with-settings` and `--build` add their paths;
  - exit 3 without git and 4 on a detached head or during a merge, each changing nothing;
  - `--new-project` commits `.aid/settings.yml` and the KB skeleton, and nothing else;
  - `--finish` commits a state file marked `Approved`; a commit made to fail exits 6 and leaves the state
    file back at FINISH, byte for byte.
- **`tests/canonical/test-writeback-state.sh`**:
  - only `--step --kb` and `--kb --field Status --value Growing` create the file; any other `--kb` write
    on a missing file exits 10 and creates nothing; every KB mode writes its keys; `--clear-build` keeps
    `status`, the record and `qa` and resets the rest;
  - setting `Approved` clears the record;
  - invalid values exit 4;
  - `--check --kb` reports each missing and inconsistent case with exit 9, and `--repair --kb` fixes it;
  - `--kb-update-log` appends to the work file; with `--mode refresh` it writes `docs` and `grade` as `--`,
    and another mode without them exits 5;
  - every file written parses through the dashboard reader.
- **`tests/canonical/test-kb-state-migration.sh`**:
  - a full `STATE.md` fixture converts to the expected `STATE.yml`;
  - running again changes nothing;
  - baselines are filled only where absent and skipped without git;
  - `pipeline.parent_branch` is filled for works in the main folder and in a registered worktree: `master`
    when it exists, the current branch when it does not, `--` without git; an existing value is kept, and a
    re-run changes nothing;
  - STEP 0 accepts a `STATE.yml`-only repository;
  - bash and PowerShell give the same bytes, with the PowerShell half in the Windows lane.
- **Dashboard**:
  - fixtures for each KB status, `Growing` and a legacy `STATE.md`;
  - the new waterfall;
  - the card texts in `test_index_html.py`;
  - the parity tests (`test_task066_kb_parity.py`, `test-dashboard-parity-h.sh`).

**Conversation samples -- `tests/conversation/samples/feature-004/`**

| Sample | Covers | Runs |
|---|---|---|
| `004-01-build-from-code` -- fixture: code, no KB; "fix the login timeout". Check: the build is offered before any work question, and no effort check is made; its questions follow the protocol; one approval, in chunks; after the yes, exactly one new commit on the checked-out branch, touching only `.aid/knowledge/`, `.aid/connectors/` and `.aid/settings.yml`, and nothing pushed; `STATE.yml` says `Approved`, and `render-kb-view.sh --check` exits 0; then the bug-fix work starts. | AC-15, AC-28 | now |
| `004-02-build-resumed-by-another-user` -- the build stops at a question; a second session, another persona. Check: it resumes at the step saved in `STATE.yml`, the open question comes first, and no work folder is created | AC-28, AC-37 | now |
| `004-03-question-the-kb-lacks` -- fixture: a fact the code shows and the KB lacks. Check: the answer cites the code; no work is created; one question offers an update; on "not now", the gap is in `.aid/knowledge/STATE.yml` `qa` and no document changed. | AC-15, AC-28 | now |
| `004-04-fact-stated` -- "we moved from SQLite to Postgres". Check: a knowledge-update work with `active_skill: aid-kb-update`; a confirmation before any edit; only the scoped documents changed, with a review ledger at or above the bar; `kb.html` re-rendered in the same commit, and a `kb_updates` entry; one final approval, the work `Completed`, and nothing pushed. | AC-15, AC-28 | now |
| `004-05-drift-yes` -- fixture: a document whose source changed after its baseline; an unrelated change request. Check: one question names that document; on yes, a `handoffs` call entry, returned; the document updated in the work; the work goes on at its step. | AC-15, AC-28 | now |
| `004-06-drift-no` -- the same fixture; the user declines and later resumes. Check: nothing written to the KB, and the same documents are not raised again | AC-15, AC-28 | now |
| `004-07-show-the-view` -- "show me what the project knows". Check: a link to `kb.html` and no file changed. Run also with a stale view: the agent says so and offers a refresh | AC-15, AC-28 | now |
| `004-08-next-backlog-item` -- "work on the next backlog item". Check: the top item is named in the reading; a work starts with `backlog.md` as a source; no backlog skill exists or runs. | AC-39 | now |
| `004-09-roadmap-idea-parked` -- "let's rethink the roadmap"; the user keeps it for later. Check: `roadmap.md` and every KB file unchanged | AC-39 | now |
| `004-10-new-project-first-decision` -- fixture: an empty folder; a bare idea through to the requirements approval, with a stack chosen. Check: before that approval, `.aid/knowledge/` holds only the skeleton (`status: Growing`, an empty `README.md` and `INDEX.md`, committed with `type: greenfield` before the work's branch); after it, `decisions.md` and `technology-stack.md` hold only approved decisions; no architecture or module-map document. | AC-18 | deferred: Feature 005 |
| `004-11-new-project-first-build` -- the first task builds a module. Check: `module-map.md` appears describing only that module, stamped at the task's commit | AC-18 | deferred: Feature 007 |
| `004-12-backlog-item-done` -- the work started in `004-08` is built. Check: its backlog item is updated as `backlog.md` says, inside the work | AC-39 | deferred: Feature 007 |

Feature 003's `003-11-roadmap-to-kb` now runs, and Feature 002's `002-13-mid-task-kb-update-returns` waits
only for Feature 007. Feature 001's `001-05-project-question` and `001-15-no-kb-offers-preparation` run
again at this feature's end.

##### Criteria traceability

| Criterion | Where satisfied | How verified |
|---|---|---|
| AC-15 | Flows (the four skills and when the agent runs them); The view; Components (approvals, `/aid-orchestrate`, Dashboard); Files and layout (summarize deleted) | KB-01 to KB-06; `test-render-kb-view.sh`; writer unit tests; `004-01` to `004-07`; `002-13` (deferred) |
| AC-18 | Components (A new project); Flows (`/aid-kb-update` START, `/aid-kb-build` START for a new project) | `004-10`, `004-11` (deferred) |
| AC-39 | Components (Roadmap, backlog and MVP); Files and layout (the KB `create` / `update` skills deleted, the two templates) | KB-01, KB-07; `004-08`, `004-09`, `003-11`; `004-12` (deferred) |

### Feature 005 — Specification with Both Business and Technical Detail

- **Priority:** Must
- **Requirements:** §5 FR-1, FR-3, FR-11, FR-15; §6 NFR-N
- **Criteria:** AC-12, AC-16, AC-44

#### Description

`/aid-specify` (today's define and specify merged) produces `REQUIREMENTS.md` made of requirements with acceptance criteria. It splits the work into features only when it delivers several user-visible capabilities. The document carries both the business view of the work (what and why) and its technical view (how). Before it starts, the agent checks the effort level and recommends a higher one when it is below high.

#### User Stories

- As an AID user, I want one requirements document, split into features only when there really are several capabilities, so that I review what matters and nothing invented.

#### Technical Specification

Serves FR-1 (the Specification phase), FR-3, FR-11, FR-15 and NFR-N, and follows FR-6, FR-17, FR-18 and
FR-20 as Features 001-004 define them. Maintainer decisions: Q1, Q11, Q17, Q22, Q23, Q47, Q61-Q70. Paths are
`canonical/` sources, rendered as in Feature 001. "The document" is a work's `REQUIREMENTS.md`; "the business
part" is its sections 1-10; "the technical part" is its section 11.

##### 1. Files and layout

| Change | Path | What |
|---|---|---|
| Rewrite | `canonical/skills/aid-specify/SKILL.md` | The Specification phase skill, for the whole work at once: its step table (see Flow), `skill-steps.md` and `question-protocol.md` cited, Feature 001's what/when `description:` (see Components), `argument-hint: "[what to specify, or what to change]"`. At most 120 lines. Goes: the feature-path argument, `--reset`, Check 1's work listing and its own worktree entry (the gate and the work record do both, Feature 002), the state map and banners. The plan-mode check stays, as one line |
| Create | `canonical/skills/aid-specify/references/` | `start.md`, `effort-check.md`, `requirements.md`, `features.md`, `design.md`, `check.md`, `approve.md`, `finish.md`, `revise.md`; `reviewer-brief.md` is rewritten, with `### What to report` (SS-13). Each at most 120 lines |
| Delete | `canonical/skills/aid-specify/references/` `state-initialize.md`, `state-continue.md`, `state-review.md`, `state-spike.md`, `state-blocked.md`, `state-done.md`, `handling-outcomes.md`, `known-issues-scope.md` | Replaced by the references above; the known-issues filter moves into `design.md` (Flow, DESIGN) |
| Delete | `canonical/skills/aid-define/` | Retired whole: the split decision moves to FEATURES, the cross-reference to CHECK |
| Rewrite | `canonical/aid/templates/requirements/requirements-template.md` | The two-part shape (see The document). Its `## Verifiable Acceptance Criteria` section stays under that heading, which `aid-plan`, `aid-detail` and `shortcut-engine.md` cite |
| Delete | `canonical/aid/templates/specs/technical-specification-template.md` (and the `specs/` folder it leaves empty) | Folded into `requirements-template.md` |
| Rewrite | `canonical/aid/templates/requirements.md` | Kept at its path as the bare scaffold START copies (see The document): the identity block and every unfilled section hold `*(pending)*`, the marker the dashboard readers already treat as not filled; sections 1-10, then `## 11. Technical Specification`. The `- **Name:**` and `- **Description:**` lines that `dashboard/reader/tests/test_feature009.py`'s `test_pf1_*` tests pin stay |
| Edit | `canonical/aid/templates/work-state-template.yml` | `interview`, `features` and `review_history` go, with their comments; `reviews: []` and `effort_check: --` come, each with its `[W]` comment (see Work state) |
| Edit | `canonical/aid/scripts/execute/writeback-state.sh` | Extends Feature 004's `--review` mode to the work file; `--pipeline` accepts the field `"Effort Check"` (see Work state) |
| Edit | `canonical/aid/scripts/execute/slice-requirements.sh` | Also reads a document that does not split (see The document, Readers of the old shape) |
| Edit | `canonical/aid/templates/skill-steps.md` § When approvals happen (Feature 002) | One new row, the business part (Q61), and one rule, the KB call on confirmation (see Approvals) |
| Edit | `canonical/aid/templates/reviewer-dispatch.md` | In § The cross-document contradiction pass (Guard 2), the `aid-define` CROSS-REFERENCE site becomes `aid-specify` CHECK (see Components); `aid-define` leaves its list of skills that render the brief structure |
| Edit | `canonical/aid/templates/reviewer-ledger-schema.md` (the ledger-path table) | The `/aid-specify <feature>` and `/aid-define <work>` rows become one: `/aid-specify` -> `.aid/.temp/review-pending/<work>-specify.md` |
| Edit | `canonical/aid/templates/work-initiation-gate.md` § 3b legacy block (Feature 002) | The `Define` and `Specify` rows re-pointed, one row added (see Migration) |
| Edit | `canonical/aid/rules.md` § Skill guide | The `/aid-define` line goes; the `/aid-specify` line is rewritten (Components) |
| Edit | `canonical/agents/aid-architect/AGENT.md` | Its "What You Do" and "Output Format" lines name § 11 "once for the work, or once per feature" instead of "that feature's section" |
| Edit | every other kept file under `canonical/` that names `aid-define`, and the comment in `dashboard/reader/derivation.py` | Re-pointed (Migration) |
| Create | `tests/canonical/test-specify.sh`, `tests/conversation/samples/feature-005/` | See Testing |

##### 2. The document

**Its shape** (`requirements-template.md`) -- one document, two parts (FR-3, Q23):

```markdown
# Requirements

- **Name:** *(pending)*
- **Description:** *(pending)*

<!-- Sections 1-10 are the business part: what and why, in the user's words.
     Section 11 is the technical part: how it will be built. -->

## 1. Objective
## 2. Problem Statement
## 3. Users & Stakeholders
## 4. Scope
## 5. Functional Requirements       -- FR-N ids
## 6. Non-Functional Requirements
## 7. Constraints
## 8. Assumptions & Dependencies
## 9. Acceptance Criteria           -- AC-N ids, each naming an observable
## 10. Priority

## 11. Technical Specification      -- a work that does not split

**Serves:** FR-1, FR-2; AC-1, AC-2, AC-3

### Approach
### What changes
### Data and interfaces
### Decisions
### Risks
### Migration                       -- only when something existing is replaced
### Testing
```

A work that splits has, in place of that section 11:

```markdown
## 11. Features

Criteria every feature must also pass: AC-7.     -- only when there are any

### Feature 001 — {Title}

- **Priority:** Must | Should | Could
- **Requirements:** FR-1, FR-3
- **Criteria:** AC-1, AC-4

#### Description
#### User Stories
#### Technical Specification

**Serves:** FR-1, FR-3; AC-1, AC-4

##### Approach
##### What changes
...                                              -- the same headings, one level down
```

**Rules**
- **The business part keeps all ten sections (Q66).** A section that does not apply holds one line, "None.";
  it is never removed, so the section numbers every skill cites stay put. Plain words, in the user's own
  terms.
- **Ids** stay as today: `FR-N` and `AC-N`, never reused or renumbered; a withdrawn one keeps its id, marked
  withdrawn. A criterion's text lives only in section 9; features and technical parts cite ids.
- **The technical part is written once for the work, or once per feature** -- never both. Each opens with a
  **Serves:** line naming the requirement and criterion ids it serves (AC-44). In a split work every
  criterion is owned by exactly one feature, or listed once on the "Criteria every feature must also pass"
  line (the convention this document's own § 11 already uses), and every requirement is served by at least
  one feature.
- **What each heading holds**:

  | Heading | Holds |
  |---|---|
  | Approach | The chosen way, in a few sentences, and the alternatives turned down, with why |
  | What changes | The files, modules and parts of the system created, edited or deleted -- a table: change, path, what -- grounded in the KB and the code |
  | Data and interfaces | Data shapes, stored state, and what other code or users call, with its contract. An idea draft's kind `shape` points (Feature 003) are settled here, under a heading of their own when they need one (an API's contract, a screen's states) |
  | Decisions | A table: decision, why, reach -- `project` (it settles a fact the KB holds or should hold: the stack, a convention, the architecture, a recorded decision) or `work` (this work only) |
  | Risks | What could go wrong and how it is contained; issues found in code this work touches, by their `known-issues.md` id |
  | Migration | What existing users, data or works must do, or what is done for them; present only when something existing is replaced |
  | Testing | How each criterion is checked (tests, scripts, conversation samples), ending with a criteria table: criterion, where satisfied, how verified |

- A heading that does not apply is left out: an empty heading reads as an unanswered question. Today's
  optional-section list (API contracts, UI, events, security, caching, migration, ...) survives in
  `design.md` as prompts for the drafting agent, not as headings.
- No `## Change Log` (as today).

**Readers of the old shape.** The old shape -- `## 11. Features` with a `#### Technical Specification` per
feature under any headings -- stays valid; nothing rewrites it.
- **`slice-requirements.sh`**: when the document has `## 11. Technical Specification`, it prints that whole
  section in place of a feature section, and the task's `**Source:**` line need not name a feature. Otherwise
  it prints the task's `### Feature NNN` section as today, for both shapes of a split document. The cited
  criteria and the identity block are printed as today, and a Source that names no criterion is still an
  error.
- **`aid-plan`, `aid-detail`, `aid-execute`** read § 11 by feature today. Reading the unsplit shape is
  Feature 006's and Feature 007's (Q67, What other features must provide). Until Feature 006 lands, a work
  whose document does not split reaches today's `aid-plan`, which stops when it finds no feature section; a
  split one also stops there, because its Check 2 wants each feature `Ready` in the `features` key, which
  nothing writes any more (Work state). No release carries that gap, since every feature ships in v4.0.0 (§7 Constraints 1); the samples that go past
  Specification wait on the deferred list.
- **`/aid-specify` START** accepts both shapes (Flow).
- **The shortcut engine** keeps writing its own § 11 `### Feature 001` until Feature 009 (Q65). That is
  the old shape, which every reader above still reads.

##### 3. Flow

The gate creates the work with `--skill aid-specify --step START --phase Specification` (Feature 002),
`/aid-orchestrate` routes a clear problem here (Feature 001), and brainstorm's FINISH passes an idea here
(Feature 003). One run covers the whole work. The depth is `intent.depth`; with none recorded, `full`
applies (Feature 002).

| Step | Reference | Worker | Advance |
|---|---|---|---|
| START | `references/start.md` (`references/effort-check.md`) | main conversation | `CHAIN` -> REQUIREMENTS; `ASK` -> REQUIREMENTS when the effort check asks; `CHAIN` -> REVISE for a change after Specification (below) |
| REQUIREMENTS | `references/requirements.md` | `aid-architect` drafts; main conversation asks | `ASK` -> REQUIREMENTS after each group; `CHAIN` -> FEATURES when nothing is open; in a fix, `CHAIN` -> CHECK, or -> FEATURES / DESIGN when the fix reaches them (Fix route) |
| FEATURES | `references/features.md` | main conversation (`aid-architect` proposes a split) | `full`: `ASK` -> DESIGN, or -> REQUIREMENTS when the user asks for a change at the checkpoint; `lite`: `CHAIN` -> DESIGN; in a fix, only the split question, then `ASK` -> DESIGN |
| DESIGN | `references/design.md` | `aid-architect` drafts (fans out `aid-researcher` as today); main conversation asks | `ASK` -> DESIGN after each group; `WAIT` -> DESIGN for an investigation only the user can make; `CHAIN` -> CHECK |
| CHECK | `references/check.md` (brief: `references/reviewer-brief.md`) | `aid-reviewer` | `CHAIN` -> REQUIREMENTS or DESIGN in a fix (Fix route); after three rounds below the bar, `ASK` per open row -- fix (Fix route), accept, or keep reviewing (-> CHECK); `CHAIN` -> APPROVE only when the grade passes or every open row is `Accepted` |
| APPROVE | `references/approve.md` | main conversation | `full`: `ASK` -> FINISH, or -> REQUIREMENTS / DESIGN in a fix when the user asks for a change; `lite`: `CHAIN` -> FINISH; in a revision, by the kind of change (REVISE below) |
| FINISH | `references/finish.md` | main conversation | `CALL` to `aid-kb-update` when owed (below), then `PASS` to `aid-plan`; in a revision, `HALT` or `PASS` back |
| REVISE | `references/revise.md` | main conversation (`aid-architect` drafts) | `CHAIN` -> CHECK; that check's fixes take the Fix route |

**Fix route.** A fix asked by CHECK's rows, by a change the user asks for at APPROVE, or by the check inside
a revision is made in the step that owns the section -- REQUIREMENTS for the business part, DESIGN for the
technical part -- with `step_detail: 'fix: <rows or change>'`, and goes straight back to CHECK. It does not
re-run the split question or the business checkpoint, and a business fix does not pass through DESIGN. Two
exceptions, each re-entering only the step it affects: a fix that changes the feature split re-enters FEATURES
for the split question alone, then DESIGN for the technical parts the new split moves; a fix that changes a
requirement or criterion a technical part serves re-enters DESIGN for those parts. Both then go on to CHECK.
What a fix changed in the business part is shown first at APPROVE.

1. **START**
   - **Reads**: the work record (request, reading, depth); the idea draft and every `draft` source, each
     resolved with `idea-drafts.sh path` and never opened as a path (Feature 003); the draft's
     `## Open questions`, asked later in their subjects, and its `## Kind` with that kind's `shape` points from
     `kind-catalog.yml`; the work's `sources:` (Feature 001); the open `qa` entries, which come first (Feature
     002); `.aid/knowledge/INDEX.md` and the documents it routes to, when a KB exists.
   - **The effort check** (Components) -- only while the work record's `effort_check` is `--` (Q64).
   - **A tracker item** the user names, or one the request traces to, is pulled in through `/aid-read-ticket`
     and added to the work's `sources:` (Feature 001, `external-sources.md`). This is the read seam that
     `state-initialize.md` Step 3b held, moved here with its wording: "Skip silently when no such ticket
     applies or no matching connector is catalogued".
   - **What is already on disk is kept.** Detection (Feature 002, use (a)) shapes how far each step goes:
     an existing business part (one an old `/aid-describe` wrote, say) is kept and REQUIREMENTS drafts only
     what is missing; existing technical sections, in either shape, are kept and DESIGN writes only the
     missing ones. Nothing is converted to the new shape.
   - `REQUIREMENTS.md` is created from `requirements.md`, the bare scaffold, when absent.
   - **A change after Specification** goes straight to REVISE, with no effort check: START is the entry step
     every hand-off writes (Feature 002), so a call from another skill, or a typed start on a work whose phase
     is already past Specification, arrives here first (below).
2. **REQUIREMENTS** -- the business part. The agent proposes; the user disposes.
   - `aid-architect` (clean context, tiered by `agent-dispatch-tiering.md`) drafts all ten sections from the
     request, the draft, the sources, the KB and the code, and writes them. A point the evidence does not
     settle is drafted as its best proposal and returned as an open point, never stated as a fact. It never
     asks the user (Feature 002).
   - The main conversation asks the open points under the question protocol: grouped by subject (scope,
     users, requirements, criteria, ...), most important first, each with its recommendation; the draft's
     open questions join their subjects. Small choices are recorded `Assumed`. Each answer is written into the
     document and recorded (`--answer`); `step_detail` names the subject (`'business part: scope; waiting for
     Q14, Q15'`).
   - **Ask only what blocks** a concrete requirement or an observable criterion: input with Feature 001's
     five items present asks nothing here. This is the shortcut engine's "ask only what is load-bearing" rule,
     moved here (Q65).
   - Every criterion names an observable (`## Verifiable Acceptance Criteria`); one that cannot is a question,
     not a line.
   - When Specification is the work's first phase, its first question carries the agent's one-line reading
     (Feature 001, Orchestration flow step 6).
3. **FEATURES** -- whether the work splits (FR-3, AC-16), then the business checkpoint.
   - **The rule**: split only when the work delivers more than one capability a user or customer can see and
     would value on its own; the test is that each could be delivered, and announced, alone. Never split by
     layer, module, size, or number of requirements or tasks. A bug fix, a refactor, a document or a small
     change never splits.
   - **No split**: nothing is asked about it; section 11 is `## 11. Technical Specification`.
   - **A split**: the agent proposes the features -- each one's title, the requirements and criteria it owns,
     and the shared criteria line -- as one question with its recommendation, and the answer decides. In `lite`
     the split first re-routes the work to `full` (`writeback-state.sh --reroute --reading <same> --depth full
     --why 'several capabilities'`), said in one line (Feature 001's depth table); the `full` rules then apply.
   - **The business checkpoint** (`full`, Q61): the business part -- with the features, when it splits -- is
     shown in chunks, most important first, with the small decisions taken so far in the same batch (Feature
     002), then one approval question, recorded `category: Approval`, `covers: requirements business part`.
     A change the user asks for reopens as a question and goes back to REQUIREMENTS. `lite` has no checkpoint.
4. **DESIGN** -- the technical part.
   - `aid-architect` drafts it from the business part, the KB and the code: once for the work, or feature by
     feature in id order (`step_detail: 'design: feature 002'`).
   - **Research** it needs is fanned out to `aid-researcher`, as today. An investigation only the user can
     make outside the conversation is a `WAIT` that says what to do (today's SPIKE); an answer still pending is
     an open question (today's BLOCKED). Both states go.
   - **Decisions with a real fork** are asked in plain words -- what changes for the user, the cost, the risk;
     the mechanism only when the user asks (FR-17 rule 3). Choices with no visible difference are the agent's:
     recorded `Assumed`, confirmed in the approval batch.
   - **Known issues**: `known-issues-scope.md`'s filter, now in `design.md`, unchanged -- issues in code this
     work touches go to `.aid/works/<work>/known-issues.md`, which `aid-plan`, `aid-execute`, `aid-deploy` and
     `aid-monitor` still read; Risks names them by id.
   - A decision that conflicts with the KB is raised with the user, never settled alone (Feature 001).
   - A kind's `shape` points carried by the draft are settled in Data and interfaces: the design that is kept
     is the technical part (Feature 003, Q22).
5. **CHECK** -- one graded `aid-reviewer` pass over the whole document, in a clean context, at a tier no lower
   than the drafting architect's. Ledger `.aid/.temp/review-pending/<work>-specify.md`, 7 columns, under
   `### What to report` (FR-21). It reports:
   - a conflict with the KB, the code, or a user's answer;
   - something stated as decided that the user never decided;
   - a criterion with no observable, or a requirement no criterion covers;
   - a technical part with no **Serves:** line, a requirement no technical part serves, or, in a split work, a
     criterion owned twice, or by no feature and not on the shared line;
   - a split that breaks the rule, or a work that delivers several capabilities and does not split;
   - a technical step that cannot be built from what it says (an edit to a path that does not exist, an
     interface nothing defines);
   - on cycle 1, the cross-document contradiction pass (Guard 2): two sections asserting different values for
     one fact. It runs once per work, because this review sees every section.

   Heading names, wording, and the headings of an old-shape document are not findings.
   - **Grade**: `grade.sh` on the ledger, against the global `minimum_grade`; recorded with `--review` (Work
     state). Below the bar, the main conversation fixes the rows by the Fix route -- business rows in
     REQUIREMENTS, technical rows in DESIGN, each fix scoped to its row -- and CHECK runs again.
   - **After three rounds below the bar** (Q69), the agent shows the user what is still open, and for each
     open row asks one question (question protocol): *fix it* (the Fix route, then CHECK), *accept it as is*,
     or *keep reviewing* (another CHECK round). An accepted row is set to `Accepted` in the ledger, with the
     user's choice noted in its Evidence cell. Every later round still below the bar asks the same way.
   - **Nothing goes on to APPROVE** unless the grade passes or the user has explicitly accepted every row still
     open.
   - It runs at every depth.
6. **APPROVE**
   - **`full`** (Feature 002's `REQUIREMENTS.md` row): first what changed in the business part since its
     checkpoint (the CHECK fixes); then the technical part in chunks, one topic per chunk, most important first,
     technical detail only when asked; the small decisions in the same batch. The message also says, when they
     apply, that the idea draft will be removed (Feature 003's deletion rule fires on this approval) and which
     `project` decisions will be recorded in the KB. Recorded `category: Approval`, `covers: REQUIREMENTS.md`.
     A change the user asks for reopens as a question and takes the Fix route, then CHECK.
   - **`lite`**: no stop. The document is approved by the confirmation before building (Feature 007), which
     also deletes the draft (Feature 003's deletion table).
7. **FINISH**
   1. **The KB call** (Q68): the `REQUIREMENTS.md` approval follows Components, The KB call on confirmation --
      in `full` it is made here; in `lite` the approval is the confirmation before building, which makes it.
      The business checkpoint approves no decision (decisions live in the technical part), so it makes none.
   2. **`PASS`**: `--handoff --to aid-plan --step <its entry step> --returns no --phase Planning --why
      'requirements approved'` (`lite`: `'requirements written'`), and `aid-plan` starts in the same turn
      (FR-8).

**Changing the document after Specification -- REVISE (Q62).** A specification is a hypothesis (decision D3):
Planning and Building can find it wrong.
- **Entry**: a `CALL` from the skill that found the problem (`aid-plan`, `aid-execute`), with the reason in
  `--why`; or the user asking to change a requirement or the design of a work already past Specification, which
  is a typed start -- a pass without a phase change (Feature 002). Both land at START, which goes on to REVISE.
  No new work is created.
- **REVISE**: scope the change (the sections and ids it touches), edit them in place, and save `step_detail:
  'revise: <what>'`. No effort check.
- **CHECK**: the same pass, scoped to the changed sections and every section that cites a changed id; its
  fixes take the Fix route.
- **APPROVE** in a revision:
  - a change to a requirement or a criterion (sections 5 or 9, or which feature owns them) (Q62, Q70):
    - `full`: one approval at once, recorded `category: Approval`, `covers: requirements change`;
    - `lite`, before the confirmation before building: no separate approval -- recorded `Assumed`, `category:
      Specification change`, it becomes part of what that confirmation covers (AC-10 keeps its one approval);
    - `lite`, once the confirmation before building is recorded (its `Approval` entry, Feature 007): one approval
      at once, as in `full`.
    During Building, such an approval is a real blocker (FR-6), not a milestone;
  - a technical-only change: no stop. It is recorded `Assumed`, `category: Specification change`, and confirmed
    in the batch of the work's next approval (Feature 002).
- **FINISH** in a revision: the KB call follows Components, The KB call on confirmation -- an approval at once,
  at any depth, makes it right after the yes; a change recorded `Assumed` gets it from the approval that
  confirms it.
  Then `HALT`, which returns an open call, or, after a typed start, `PASS` back to the skill that drives the
  work's phase, at its entry step, without `--phase` (as Feature 003's side ideas do).

##### 4. Work state

- **No new record keys**: steps, `step_detail` and hand-offs are Feature 002's.
- **`qa` entries this skill writes** (Feature 002's shape): `Effort level`; the requirement and design questions,
  by subject; `Approval`, with `covers` `requirements business part`, `REQUIREMENTS.md` or `requirements change`;
  `Specification change` (`Assumed`).
- **Gone from `work-state-template.yml`**: `interview` (with its ten `sections`), `features` and
  `review_history`. Their writers were `aid-describe` (gone with Feature 003), `aid-define` and the old
  `aid-specify`; no writer remains. Progress inside Specification is the work record; progress across features
  is `step_detail`. Two readers of `features` remain until Feature 006 removes them (What other features must
  provide): `aid-plan` § Check 2, which wants each feature `Ready`, and `aid-detail`'s `task-decomposition.md`,
  which reads "Spike Needed" from it. Old works keep the keys until Feature 006's migration drops them; the
  dashboard readers already read a work without them (their `features` list is never filled today).
- **`effort_check`** -- new, written once by START when the effort check runs, whatever it finds
  (`--pipeline --field "Effort Check" --value <the level read, or unknown>`), before any question it asks.
  While it is `--` the check is owed; once set, re-entering START never runs it again (Q64). The writer accepts
  `--`, `unknown`, or a level name of lowercase letters; anything else exits 4.
- **`reviews`** -- new, one entry per graded review of the work's documents:

  ```yaml
  # [W] append-only, newest last: at, grade, by, notes
  reviews:
    - at: '2026-10-20T10:00:00Z'
      grade: A
      by: aid-specify
      notes: 'REQUIREMENTS.md; ledger <work>-specify.md'
  ```

  The dashboard readers ignore keys they do not show; SS-08 parses the template with no warning.
- **Writer -- an extension of Feature 004's `--review` mode.** Feature 004 defines `--kb --review --grade G
  --notes T` for the KB state file. Without `--kb`, the same mode appends the same entry (`at`, `grade`, `by`
  = the saved `active_skill`, `notes`) to the work's `STATE.yml` `reviews`, the file resolved like every work
  write. Same grade validation (exit 4), lock and atomic rename. Features 006 and 007 may use it for their own
  reviews.

##### 5. Components

**`/aid-specify` description and guide line** (Feature 001's shape; final text set at build):
- `description:` "Write a work's requirements -- what and why, with acceptance criteria -- and how it will be
  built, split into features only when the work delivers several capabilities. Use when a work's problem is
  clear and must be specified before planning, or when approved requirements must change."
- Skill-guide line, within SG-03's limit: `` - `/aid-specify` -- write the requirements and how they will be built; before planning ``
- The `/aid-define` line goes, so SG-02 still matches `canonical/skills/` both ways.

**Effort check** (`references/effort-check.md`; FR-15, AC-12, Q17, Q63, Q64):
- **When**: once per work, as Specification starts -- START, while `effort_check` is `--` (Work state). Not in
  REVISE, never again on a later entry to START (a resume, or a pass back after a side idea), never when
  building the KB (Feature 004).
- **Reading the level**: one row per supported tool -- where that tool keeps the reasoning effort of the main
  conversation (a settings file, an environment variable, a documented command), how to read it without
  changing anything, and how its level names compare with "high". The rows are filled at build time from each
  tool's own documentation; a tool with no documented place is marked "cannot be read". The agent only reads;
  it never writes a tool setting.
- **High or above**: nothing is said; only `effort_check` is recorded.
- **Below high**: one question, `category: Effort level`, importance high -- "Specification works best at high
  effort or above; this session runs at <level>." Recommendation: raise it to high, then go on. Options: raise
  it (the agent says how, from the table) / go on at <level>. When the tool applies a new level only in a new
  session, the agent says so; the work resumes at REQUIREMENTS, the step START saved.
- **Cannot be read** (Q63): one confirmation question, same category and importance -- "I cannot see this
  tool's effort level. Specification works best at high or above." -- with how to set it when the table knows.
  Recommendation: set it to high if it is lower, then go on.
- It is a question, not an approval: a `lite` work still has exactly one approval before building (AC-10).
- Sub-agents keep the effort their tier sets (`agent-dispatch-tiering.md`); the check concerns the main
  conversation, which reads the request and talks with the user.

**Approvals** -- `skill-steps.md` § When approvals happen gains one row (Q61), placed above the `REQUIREMENTS.md`
row, and Feature 002's table carries it:

| Moment | `full` | `lite` |
|---|---|---|
| The business part of `REQUIREMENTS.md`, before the technical part is designed (Specification) | approve | -- |

The revision approvals of Q62 are not a new moment of the table: they are `/aid-specify`'s, stated in
`revise.md`, and recorded like every approval.

**The KB call on confirmation** -- one rule, added under the table in `skill-steps.md`, so it binds every skill
that runs an approval: **any approval that approves a decision of reach `project`** makes, right after the yes,
the single `CALL` to `/aid-kb-update` (`change`) carrying every such decision it approved (Q68) --
`--handoff --to aid-kb-update --step START --why 'approved decisions: <titles>' --returns yes`, returning to
that approval's step. It covers decisions approved directly (the `REQUIREMENTS.md` approval, the confirmation
before building of a `lite` work, an approval at once in a revision at any depth) and decisions confirmed from
an `Assumed` entry (a `Specification change`, or any other) by `aid-plan`'s `PLAN.md` approval, `/aid-execute`'s
confirmation or a milestone, or any later approval. Only when a KB exists: with none there is no call, and the
agent says once per work that the KB is not built, so the decision will be recorded when it is (Feature 004, No
KB: one rule). The skill running that approval makes the call; no decision waits for a particular skill.

**The contradiction pass** -- `reviewer-dispatch.md`'s site table: the `aid-define` CROSS-REFERENCE row becomes
`aid-specify` CHECK -- receives `REQUIREMENTS.md`, every section -- covers Specification's own output, once per
work. The paragraph "`aid-specify` deliberately gets no invocation" (it reviewed one feature at a time) is
replaced by one line saying CHECK reviews the whole document once per work, so it hosts the pass. The
`aid-plan` row stays as it is until Feature 006.

**`aid-architect`** -- its Output Format line: "Technical specification: written into `REQUIREMENTS.md § 11`,
once for the work or once per feature, per `templates/requirements/requirements-template.md`."

**Kept invariant**: `/aid-specify` writes only `REQUIREMENTS.md`, `known-issues.md` and, through the writer, the
work's `STATE.yml`. It changes a KB document only through the `/aid-kb-update` call.

##### 6. What other features must provide

| Feature | Must provide | Waiting on it |
|---|---|---|
| 006 | `aid-plan` reads both shapes: an unsplit document's `## 11. Technical Specification` as one unit, with tasks citing requirement and criterion ids and no feature; a split document by feature (Q67). Its work-state migration drops `interview`, `features` and `review_history` from old works, and fills the record of old Define and Specify works with the legacy rows of Migration. Its `PLAN.md` approval applies `skill-steps.md`'s KB call on confirmation (Components): when it confirms an `Assumed` entry holding a `project` decision, the one call. The two reads of the `features` key go: `aid-plan` § Check 2's `Ready` gate and `aid-detail` `task-decomposition.md`'s "Spike Needed" read (a spike is now a `WAIT` inside Specification). The dashboard's feature count (the "Full path" summary line in `home.html`) follows its plan model | `005-07` past Specification, `005-13`, `002-08`, `002-09` |
| 007 | Its confirmation before building and its milestones apply `skill-steps.md`'s KB call on confirmation (Components): the confirmation approves a `lite` work's `REQUIREMENTS.md` and so its `project` decisions, and any of them may confirm an `Assumed` one; Feature 003's draft deletion already fires on that confirmation (`skill-steps.md`). A task that finds the document wrong makes a `CALL` to `/aid-specify` (REVISE) with the reason: today's `IMPEDIMENT` routes of type `wrong-assumption` and `architecture-conflict` to Specify become that call. `aid-execute` reads the unsplit shape through the slice | `005-11`, `005-12` |
| 009 | The shortcut engine's CAPTURE and SPEC states go (Q65), and with them its `SP-08` row on the shared exempt list; until then the engine writes `REQUIREMENTS.md` itself, in the old shape. Its action skills pass to `/aid-specify` with the kind, and the catalog fields that shape a technical part are read by `design.md` | -- |

##### 7. Migration

| Old | New |
|---|---|
| `/aid-define` | Say what you want; `/aid-specify` writes the requirements and splits them into features only when the work delivers several capabilities |
| `/aid-specify work-NNN/feature-NNN`, `/aid-specify --reset` | `/aid-specify` covers the whole work; to change approved requirements, say what should change |

- **Release notes**: the rows join the old -> new table (AC-24), drafted in `.aid/knowledge/backlog.md` § Next
  Release. No stubs (M1).
- **Installed projects**: `aid update` removes `aid-define`, the deleted references and the two deleted templates
  through the install manifest (decisions.md § D9).
- **Existing works**:
  - **Legacy block** of `work-initiation-gate.md` § 3b: Feature 002's old-phase rows `Define` -> `/aid-define` and
    `Specify` -> `/aid-specify` become `Define` or `Specify` -> `/aid-specify` at **START**, and one row is added:
    `pipeline.initiator` or `active_skill` `aid-define` -> the same. Feature 003's `aid-describe` row already
    points here. START keeps what the old work wrote (Flow). Feature 006's migration uses the same rows.
    `test-work-initiation-gate.sh` gains a `--check` fixture for each changed row.
  - Old documents keep their shape (The document); old `interview`, `features` and `review_history` keys wait for
    Feature 006's migration.
  - Old ledgers (`specify-<feature>.md`, `interview-<work>-cross-ref.md`) go with `.aid/.temp/`'s own clean-up.
- **Re-pointing**: every kept file under `canonical/`, and `dashboard/home.html`, that names `aid-define` is
  re-pointed to `/aid-specify` or reworded. Exempt: the gate's legacy block and `canonical/aid/scripts/migrate/`,
  which read old shapes. SP-02 enforces it. The sites today, beyond Files and layout:
  `downstream-worktree-entry.md` and `worktree-lifecycle.md` (their consumer lists; `aid-specify` no longer
  enters a worktree itself), `reviewer-ledger-schema.md`, `shortcut-scaffolding/analyze-report.md`,
  `shortcut-engine.md` § State: SPEC (its sentence naming define's CROSS-REFERENCE is reworded; the engine itself
  stays, Q65), `work-state-template.yml` (its comments go with the keys), and
  `aid-kb-build/references/reviewer-brief.md` (moved there by Feature 004). Outside `canonical/`: the comment in
  `dashboard/reader/derivation.py`; the comment in `bin/aid`'s state converter stays, because it describes old works.
- **Site**: `site/scripts/skills/` (roster, groups), `site/scripts/.skills-manifest.json`,
  `site/scripts/lib/flow-graph/` (`model.mjs`, `extract-dispatch.mjs`, `advance.mjs`) and their `__tests__`;
  pages and flows regenerated by `site/scripts/gen-skills.mjs`.
- **Lists other features own** -- each changes in the same commit as the skill it concerns:
  - **Deferred list** (`tests/conversation/deferred.tsv`): the `skill:aid-define` and `skill:aid-specify` rows go
    (`aid-specify` is covered by `005-01` and `005-04`); `002-06`, `002-11`, `002-12`, `003-06`, `003-08`, `003-09`
    and `004-10` run now; `002-07` waits only for Feature 007, and `002-08` and `002-09` for Features 006 and 007;
    this feature's deferred samples are added.
  - **Description exempt list** (`test-skill-guide.sh` SG-04): the `aid-define` row goes, and `aid-specify`'s if
    it has one.
  - **SS-13** finds the rewritten brief by its glob; `aid-define`'s goes with its skill.
  - **Shared exempt list** (`tests/canonical/skill-steps-exempt.tsv`): one row -- `canonical/aid/templates/shortcut-engine.md`,
    checks `SP-08`, owner Feature 009 (Q65) -- so the release check keeps the engine's own requirements writing
    from shipping undone.
- **Suites**:
  - `test-scoped-review-cycles.sh`: SC10's three sites become `aid-specify/references/check.md`,
    `aid-plan/references/review-deliverables.md` and `aid-detail/references/review.md`; SC11 flips -- it now
    asserts that `aid-specify` invokes the pass in `check.md` and in no other reference, once per work.
  - `test-downstream-worktree-entry.sh`: its `aid-define` and `aid-specify` assertions go.
  - `test-state-review-surface.sh`: the `aid-define` brief path goes.
  - `test-work-state-template.sh`: WS21 (`features`) and WS22 (`review_history`) go; one assertion for `reviews:
    []`, one for `effort_check: --`, each with its `[W]` comment, comes.
  - `test-shared-prune.sh`, `test-shared-remove.sh` and the `test-aid-cli-parity.sh` drift row use `aid-define` as a
    sample installed skill; they switch to one that stays (`aid-plan`).
  - `test-ticket-retirement-structural.sh`: its `SPECIFY_INIT` path (in the T000 setup loop and the seam map)
    becomes `canonical/skills/aid-specify/references/start.md`, which carries the read seam and its silent-skip
    sentence, so T045, T046 and T097 hold there; its template assertions follow the new template.
  - `test-connector-consumption-linkage.sh` reads the template and follows its new shape.
  - `dashboard/reader/tests/test_feature009.py`: its `test_pf1_*` tests keep reading
    `canonical/aid/templates/requirements.md`, which keeps its path and its `- **Name:**` / `- **Description:**`
    lines with `*(pending)*`; nothing changes.
  - `test-pipeline-status-walkthrough.sh` and `test-writeback-state.sh` follow the deleted references;
    `test-artifact-discipline.sh` AD13 ceilings drop to the new measured counts.
  - Dashboard fixtures that name `aid-define` or `aid-specify` as an old work's skill stay: they are old works'
    inputs.
  - Removed assertions go to `tests/coverage-accepted-removals.tsv`; the `tests/coverage-rehome-allowlist.tsv` rows
    for the deleted assertions go; `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv` are re-recorded.
- **User documentation** waits for the final pass (Q40, AC-45). The only edit now: the numbers
  `test-doc-counts.sh` asserts.
- **KB** (no work ids):
  - `architecture.md` and `pipeline-contracts.md` (the Define and Specify rows become one Specification row; the
    state machines; the artifact rows for `REQUIREMENTS.md` and the feature section; the loops that route to
    Specify now reach `/aid-specify`'s REVISE);
  - `artifact-schemas.md` (the two-part shape; `interview`, `features`, `review_history` gone; `reviews`);
  - `domain-glossary.md` (feature as a business capability, business part, technical part, effort check; define
    goes);
  - `capability-inventory.md`, `module-map.md`, `quality-gates.md` (one Specification check replaces the
    cross-reference and per-feature gates), `test-landscape.md` (the new suite);
  - `tech-debt.md`: SY-6 and W5-5 narrowed, their `aid-define` and `aid-specify` sites gone;
  - `decisions.md` gains "one Specification skill: a feature is a capability a user values on its own, and the
    technical part is written once per work, or once per feature when the work splits". It **amends D29**: the
    one-document rule and ids cited, never copied, stay; "a feature is an independently implementable unit" and
    "every criterion is owned by exactly one feature" become the business-capability rule and "owned by one
    feature, or shared by all" -- marked in the summary table and in D29's section.
  - Then `INDEX.md` is regenerated and `kb.html` rendered by the script (Feature 004).

##### 8. Testing

Per NFR-T (Q35): unit tests and static checks now; a sample that needs a later feature waits on the
deferred-tests list.

**Static checks -- `tests/canonical/test-specify.sh`** (picked up by `tests/run-all.sh`; added to the suite list
of `.github/workflows/installer-tests.yml`):

| Group | Asserts |
|---|---|
| SP-01 | `canonical/skills/aid-define/` and `canonical/aid/templates/specs/` are absent; `canonical/aid/templates/requirements.md` exists, its identity lines hold `*(pending)*`; `aid-specify`'s nine new references and its brief exist; none of its deleted references does |
| SP-02 | `aid-define` is named by no kept file under `canonical/`, nor by `dashboard/home.html`, outside the legacy block of `work-initiation-gate.md` and `canonical/aid/scripts/migrate/` |
| SP-03 | `aid-specify`'s step table has START, REQUIREMENTS, FEATURES, DESIGN, CHECK, APPROVE, FINISH and REVISE; FINISH advances by `PASS` and `finish.md` names `aid-plan`, `--phase Planning`, `aid-kb-update` with `--returns yes`, and the No-KB rule; `revise.md` names `requirements change` and `Specification change`; `check.md` names the three choices after three rounds below the bar (fix, accept, keep reviewing) and the ledger status `Accepted` (Q69) |
| SP-04 | `start.md` cites `effort-check.md`; `effort-check.md` has a row for each of Claude Code, Codex, Cursor, Antigravity and Copilot CLI and states the "cannot be read" path; no file under `canonical/skills/aid-kb-build/` cites it |
| SP-05 | `requirements-template.md` has the headings `## 1.` to `## 10.`, `## 11. Technical Specification`, `## 11. Features`, the technical headings of The document, a `**Serves:**` line, and `## Verifiable Acceptance Criteria` |
| SP-06 | `work-state-template.yml` has no `interview:`, `features:` or `review_history:` key and has `reviews: []` and `effort_check: --`, each with its `[W]` comment; no file under `canonical/skills/` or `canonical/aid/templates/` other than that template has a line opening with `interview:`, `features:` or `review_history:` |
| SP-07 | `skill-steps.md` § When approvals happen has the business-part row; `reviewer-dispatch.md`'s Guard 2 site table names `aid-specify` CHECK and no `aid-define` row; `skill-steps.md` states the KB call on confirmation -- for any approval that approves a `project` decision, directly or from an `Assumed` entry -- and names `aid-kb-update` |
| SP-08 | No file under `canonical/skills/` or `canonical/aid/templates/` other than `aid-specify`'s authors `REQUIREMENTS.md` in a state of its own: no `## State: CAPTURE` or `## State: SPEC` heading. Files of entries on the shared exempt list marked for SP-08 are skipped (Q65: `shortcut-engine.md`, owner Feature 009) |

**Unit tests**
- `tests/canonical/test-slice-requirements.sh`: an unsplit document prints `## 11. Technical Specification`, the
  cited criteria and the identity block, with a Source that names no feature; the output for a split document,
  in both shapes, is unchanged; a Source naming no criterion still fails.
- `tests/canonical/test-writeback-state.sh`: `--review` without `--kb` appends a `reviews` entry to the work file,
  with `by` the saved skill; a bad grade exits 4 and changes nothing; the file parses through the dashboard reader;
  `--kb --review` is unchanged. `--pipeline --field "Effort Check"` accepts `--`, `unknown` and a level name, and
  refuses anything else with exit 4.
- `tests/canonical/test-scoped-review-cycles.sh`: SC10 and SC11 as in Migration.

**Conversation samples -- `tests/conversation/samples/feature-005/`** (frontmatter `skills: aid-specify`)

| Sample | Covers | Runs |
|---|---|---|
| `005-01-bug-fix-no-features` -- fixture: code and a KB; "exporting an empty list crashes". Check: the document has sections 1-10 (those that do not apply say "None.") and `## 11. Technical Specification` with a `**Serves:**` line; no `## 11. Features`; no split question; the questions follow the protocol | AC-16, AC-44, AC-28 | now |
| `005-02-two-capabilities-split` -- a request for two capabilities a user would each value alone. Check: one split question with its recommendation; after yes, `## 11. Features` with two features, each with its own technical part and `**Serves:**` line; every criterion owned once or on the shared line; `intent.depth` is `full` | AC-16, AC-44, AC-28 | now |
| `005-03-many-requirements-one-capability` -- many requirements, one capability. Check: no split proposed; one technical part | AC-16 | now |
| `005-04-effort-below-high` -- fixture: the host's effort set below high (how, confirmed at build with `effort-check.md`'s Claude Code row). Check: the effort question comes before any requirements question, importance high, recommending high; a `qa` entry `Effort level` and `effort_check` set; a second session that resumes the work is not asked again | AC-12, AC-28 | now |
| `005-05-effort-cannot-be-read` -- fixture: the installed `effort-check.md` marks the host "cannot be read". Check: one confirmation question saying so and recommending high, asked once | AC-12 | now |
| `005-06-full-two-checkpoints` -- a `full` work from an idea draft. Check: a `covers: requirements business part` approval before any technical question; the final approval in chunks, naming the draft's removal; both approvals in `qa`; the draft deleted after the second; a `reviews` entry at or above the bar | AC-9, AC-10, AC-44 | now |
| `005-07-lite-ticket-no-stop` -- a complete ticket. Check: no approval question in Specification; small decisions recorded `Assumed`; the document written with its `reviews` entry; a `handoffs` pass to `aid-plan` with phase Planning. The checks stop at that pass | AC-10, AC-44 | now |
| `005-08-decision-to-kb` -- fixture: a KB; the design picks a new library. Check: after the final approval, one `handoffs` call to `aid-kb-update`, returned, one `kb_updates` entry, the decision in `decisions.md`. Run also with no KB: no call, and one line saying the decision will be recorded when the KB exists | AC-15 | now |
| `005-09-change-requirement-later` -- fixture: a `lite` work at Planning; the user asks to change a criterion, then a technical detail. Check: neither change asks an approval; both are recorded `Assumed`, `Specification change`, for the confirmation before building to cover; no `Approval` entry is written; the work goes back to `aid-plan`. Run also as a `full` work: the criterion change asks one approval at once, the technical change asks nothing | AC-10, AC-37 | now |
| `005-13-assumed-decision-to-kb-at-plan-approval` -- fixture: a KB; a `full` work at Planning; the user asks for a technical change that picks a new library. Check: no approval asked for it and no KB change before the `PLAN.md` approval; after that approval, one `handoffs` call to `aid-kb-update`, returned, with the decision in `decisions.md` | AC-15 | deferred: Feature 006 |
| `005-12-lite-change-after-confirmation` -- fixture: a `lite` work in Building, its confirmation before building recorded; the user asks to change a criterion. Check: one approval at once, recorded `covers: requirements change`, before any further task runs | AC-10, AC-32 | deferred: Feature 007 |
| `005-10-old-define-work` -- fixture: a work at `phase: Define` with an old business part and no record. Check: recovery proposes `/aid-specify` at START as one question; after yes, the old sections are kept, not rewritten | AC-37 | now |
| `005-11-lite-decision-to-kb-at-confirmation` -- a `lite` work whose design picks a new library. Check: no KB change before the confirmation before building; after its yes, one call to `aid-kb-update` | AC-15 | deferred: Feature 007 |

Feature 001's `001-08-bare-idea` and `001-09-bug-fix-phases` run again at this feature's end.

##### Criteria traceability

| Criterion | Where satisfied | How verified |
|---|---|---|
| AC-12 | Flow (START); Components (Effort check) | SP-04; `005-04`, `005-05`; `004-01` (no check before building the KB) |
| AC-16 | The document; Flow (REQUIREMENTS, FEATURES, CHECK) | SP-05; `005-01`, `005-02`, `005-03` |
| AC-44 | The document (two parts, **Serves:** lines, one technical part per work or per feature); Flow (DESIGN, CHECK) | SP-05; `test-slice-requirements.sh`; `005-01`, `005-02`, `005-06`, `005-07` |

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

Serves FR-1 (the Planning phase), FR-11 and FR-12, and follows FR-6, FR-17, FR-18 and FR-20 as Features 001-005
define them. Maintainer decisions: Q3, Q5, Q11, Q18, Q34, Q35, Q67, Q68, Q71-Q75. Paths are `canonical/` sources,
rendered as in Feature 001. "The plan" is a work's `PLAN.md`; "a task file" is a task's instruction file,
`tasks/task-NNN/DETAIL.md`; "the work file" is the work's `STATE.yml`.

##### 1. Files and layout

| Change | Path | What |
|---|---|---|
| Rewrite | `canonical/skills/aid-plan/SKILL.md` | The Planning phase skill, for the whole work at once: its step table (see Flow), `skill-steps.md` and `question-protocol.md` cited, Feature 001's what/when `description:` (see Components), `argument-hint: "[what to plan, or what to change in the plan]"`. At most 120 lines. Goes: Check 1's work listing and its own worktree entry (the gate and the work record do both, Feature 002), Check 2 with its `features` `Ready` gate, `--reset`, the state map and banners, `## Feedback Loops` (its delivery-level `qa` writes). The plan-mode check stays, as one line |
| Create | `canonical/skills/aid-plan/references/` | `start.md`, `breakdown.md`, `check.md`, `approve.md`, `finish.md`, `revise.md`; `reviewer-brief.md` is rewritten, with `### What to report` (SS-13). Each at most 120 lines |
| Delete | `canonical/skills/aid-plan/references/` `first-run-loop.md`, `review-deliverables.md` | Replaced by the references above |
| Delete | `canonical/skills/aid-detail/` | Retired whole: task breakdown moves to BREAKDOWN, its type table and default criteria into `breakdown.md`, its review into CHECK. `execution-graph-generation.md` goes: waves are derived by `derive-waves.sh` (The plan) |
| Create | `canonical/aid/templates/plan-template.md` | The plan's shape (see The plan); type `template-own` |
| Rewrite | `canonical/aid/templates/task-detail-template.md` | The task file's shape (see The task file) |
| Delete | `canonical/aid/templates/delivery-state-template.yml`, `task-state-template.yml`, `delivery-plans/` | No delivery or task state file, and no second task shape |
| Edit | `canonical/aid/templates/work-state-template.yml` | The planning part (see Work state); `pipeline.path` and the top-level delivery keys go; the header's zone, "derived view" and full-layout-omission paragraphs are replaced by a short statement of the single layout |
| Edit | `canonical/aid/scripts/execute/writeback-state.sh` | The single layout, `--plan-sync`, the re-render, exit 11; `--create --path` and the `"Pipeline Path"` field go (see Work state) |
| Edit | `dashboard/scripts/writeback-state.sh` (the deliberate fork) | The same single-layout targets for its task writes (rename, notes); it keeps `Deploy` |
| Edit | `canonical/aid/scripts/execute/derive-waves.sh` | New `--plan <work-dir>` mode that writes the plan's checklist; the `<plan.md>` table modes go; `--from-tasks` stays (see The plan) |
| Edit | `canonical/aid/scripts/execute/slice-requirements.sh` | Finds the task file at `tasks/task-NNN/DETAIL.md` only; reads the new Source forms (see The task file) |
| Edit | `canonical/aid/templates/skill-steps.md` § When approvals happen (Feature 002) | One rule: the plan approval that starts building is also the confirmation before building (Q73; see Approvals) |
| Edit | `canonical/aid/templates/reviewer-dispatch.md` | Guard 2's site table: the `aid-plan` row becomes `aid-plan` CHECK over the plan, every task file and `REQUIREMENTS.md`, covering Planning's own output; the `aid-detail` row goes, and `aid-detail` leaves the list of skills that render the brief structure |
| Edit | `canonical/aid/templates/reviewer-ledger-schema.md` (the ledger-path table) | The `/aid-plan` and `/aid-detail` rows become one: `/aid-plan` -> `.aid/.temp/review-pending/<work>-plan.md` |
| Edit | `canonical/aid/templates/work-initiation-gate.md` § 3a and § 3b (Feature 002) | § 3a passes no `--path`; § 3b's legacy block is removed and an old-layout check takes its place (see Migration) |
| Edit | every allocation point that passes `--path` to the gate's `--create` (Feature 002's list) | `--path lite` becomes `--depth lite`; `--path full` is dropped (Q11) |
| Edit | `canonical/aid/templates/shortcut-engine.md` § State: PLAN Step 3, § State: DETAIL Steps 3-4, and its `pipeline.path` lines | The direct edits of `delivery_lifecycle` and `tasks_lifecycle` and the `--lifecycle Specified` write become one `writeback-state.sh --plan-sync`; `pipeline.path: lite` becomes `intent.depth` `lite` (see Components). The states themselves stay until Feature 009 |
| Edit | `canonical/skills/aid-deploy/SKILL.md` and `references/state-selecting.md` | Delivery and task state read from the work file's `deliveries` and `tasks_lifecycle`; the `deliveries/delivery-NNN/` workspace lines go |
| Edit | `canonical/aid/rules.md` § Skill guide | The `/aid-detail` line goes; the `/aid-plan` line is rewritten (Components) |
| Edit | `canonical/agents/aid-architect/AGENT.md` | "What You Do" and "Output Format": task files each declare their `**Depends on:**` and their delivery; the plan's shape is `plan-template.md` |
| Edit | `bin/aid`, `bin/aid.ps1` | The work-state step of format 6 (see Migration) |
| Edit | `dashboard/reader/models.py`, `parsers.py`, `reader.py`, `derivation.py`, `state_schema.py` (its docstring example names `intent.depth` instead of `pipeline.path`), `dashboard/server/reader.mjs`, `server.py` § `_ser_work`, `server.mjs`, `dashboard/home.html` | See Components, Dashboard |
| Edit | every other kept file under `canonical/`, and `dashboard/home.html`, that names `aid-detail`, a deleted template or reference, or a `deliveries/delivery-NNN/` path | Re-pointed (Migration) |
| Create | `tests/canonical/test-plan.sh`, `tests/canonical/test-work-state-migration.sh`, `tests/conversation/samples/feature-006/` | See Testing |

##### 2. The plan and the task file

**The task file is the only source (Q71).** Each task's `tasks/task-NNN/DETAIL.md` holds its delivery, its
dependencies and what to build. The plan's checklist is generated from the task files and the work file, so the
two never disagree. The task file keeps today's folder at the work root -- the lite layout, which the writer,
`slice-requirements.sh`, `derive-waves.sh --from-tasks` and the dashboard already read -- because a bare
`tasks/task-NNN.md` is the old monolithic layout to the migration's era detection.

**The task file** (`task-detail-template.md`) -- instructions for the building agent, no state:

```markdown
# task-NNN: {Title -- a short noun phrase naming what the task produces}

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id NNN --field State.

**Type:** RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE

**Source:** delivery-NNN -> FR-2 -> AC-3, AC-5                  -- a work that does not split
**Source:** feature-NNN -> delivery-NNN -> FR-2 -> AC-3, AC-5    -- a work that splits

**Depends on:** task-NNN [, task-NNN] | --

**Scope:**
- {what this task produces or changes; one type per task}

**Acceptance Criteria:**
- [ ] {each names an observable}
- [ ] All section-6 quality gates pass
```

- **Source** names the delivery the task belongs to, then the requirement and criterion ids it serves, and the
  feature only in a split document (Feature 005, Q67). At least one `AC-N` is required, as today.
  `slice-requirements.sh` already extracts the `AC-N` ids anywhere in the line and the feature from `feature-NNN`,
  so an unsplit Source slices to `## 11. Technical Specification` (Feature 005) and a split one to its feature
  section. The old form `feature-NNN-{name} -> delivery-NNN -> AC-N` still reads.
- **Depends on** may name a task of the same delivery or of an earlier one, never of a later one.
- No `STATE` note, no `ticket_ref`, no "Spike Needed" rule (a spike is a `WAIT` inside Specification, Feature 005).

**The plan** (`plan-template.md`) -- an improved TODO list (FR-12, AC-19):

```markdown
# Plan -- {Work name}

<!-- Deliveries are written here. Each delivery's checklist is generated by derive-waves.sh from
     the task files and STATE.yml: change a task file, never a checklist line. -->

### delivery-001: {Name}

- **Delivers:** {what a user can use or check once it is done}
- **After:** -- | delivery-NNN
- **Acceptance criteria:** AC-1, AC-2; every delivery: AC-7

<!-- checklist: begin -->
**Wave 1**
- [x] [task-001](tasks/task-001/DETAIL.md) -- Session length setting (IMPLEMENT) -- after: --
**Wave 2**
- [ ] [task-002](tasks/task-002/DETAIL.md) -- Refresh the session on activity (IMPLEMENT) -- after: task-001 -- In Progress
- [ ] [task-003](tasks/task-003/DETAIL.md) -- Sign-in timeout tests (TEST) -- after: task-001
<!-- checklist: end -->
```

- **Acceptance criteria** cite ids only; the text lives in `REQUIREMENTS.md` § 9 (Feature 005). Each criterion is
  listed by exactly one delivery -- the one in which it becomes checkable -- except those on the document's
  "every feature must also pass" line, which every delivery lists. A criterion a delivery needs and the document
  lacks is added through `/aid-specify` REVISE, never written here.
- **The checklist**: wave headings, then one line per task: checkbox (`[x]` when Done), its id as a relative link to
  its task file (`[task-NNN](tasks/task-NNN/DETAIL.md)`, Q3, FR-12), title, type, its dependencies, and its state when
  it is neither `Pending` nor `Done`.
- **No other sections.** `## Cross-Cutting Risks` and `## Deferred` go: risks live in the technical part's Risks,
  and a requirement left unplanned is a change to the requirements, not a plan entry.

**Waves (Q18)** are never stored. `derive-waves.sh --plan <work-dir>` reads every task file (its id from the
folder, its delivery from Source, its dependencies) and the work file's task states, and writes each delivery's
checklist between its markers, each task line linking to its task file, using the same Kahn sort the script runs today: per delivery, a task enters the
first wave in which every dependency of the same delivery is already placed; a dependency on an earlier
delivery's task is met.

| Use | Does |
|---|---|
| `derive-waves.sh --plan <work-dir>` | Writes every checklist (temporary file, renamed into place); a byte-identical no-op when nothing changed. Exit 0 written or current; 2 a malformed graph -- a cycle, an undefined task, or a dependency on a later delivery's task -- with the plan untouched; 3 no `PLAN.md` |
| `derive-waves.sh --plan <work-dir> --check` | Writes nothing; exit 0 current, 1 stale, 2 malformed, 3 no plan |
| `derive-waves.sh --from-tasks <work-dir>` | Unchanged: the dependency table and wave blocks that `complexity-score.sh` and `compute-block-radius.sh` read |

- **A delivery with tasks and no stanza** gets a bare `### delivery-NNN` heading and its checklist at the end of the
  plan; CHECK then reports the missing stanza lines.
- **Old plans**: on its first run in a stanza that has no markers, the script replaces the stanza's execution-graph
  section (`#### Execution Graph`, `### delivery-NNN Execution Graph`, or an old lite plan's top-level
  `## Execution Graph`) and its `wave-map` block -- generated or duplicated content, the dependencies being in the
  task files -- with the checklist. The authored lines are never rewritten.
- The `<plan.md> [--write|--check]` table modes go with the tables they read.
- **Dependencies**: bash and awk, as today.

##### 3. Flow

Specification passes the work here with `--phase Planning` (Feature 005); typing `/aid-plan` on a work already
past Planning is a typed start (Feature 002). One run covers the whole work. The depth is `intent.depth`; with
none recorded, `full` applies (Feature 002).

| Step | Reference | Worker | Advance |
|---|---|---|---|
| START | `references/start.md` | main conversation | `CHAIN` -> BREAKDOWN; `CHAIN` -> REVISE for a change after Planning (below) |
| BREAKDOWN | `references/breakdown.md` | `aid-architect` drafts; main conversation asks | `ASK` -> BREAKDOWN after each group; `CHAIN` -> CHECK when nothing is open; in a fix, `CHAIN` -> CHECK |
| CHECK | `references/check.md` (brief: `references/reviewer-brief.md`) | `aid-reviewer` | `CHAIN` -> BREAKDOWN in a fix; after three rounds below the bar, `ASK` per open row -- fix, accept, or keep reviewing (-> CHECK); `CHAIN` -> APPROVE only when the grade passes or every open row is `Accepted` |
| APPROVE | `references/approve.md` | main conversation | `full`: `ASK` -> FINISH, or -> BREAKDOWN in a fix when the user asks for a change; `lite`: `CHAIN` -> FINISH; in a revision, by the kind of change (REVISE below) |
| FINISH | `references/finish.md` | main conversation | `CALL` to `aid-kb-update` when owed (below), then `PASS` to `aid-execute`; in a revision, `HALT` or `PASS` back |
| REVISE | `references/revise.md` | main conversation (`aid-architect` drafts) | `CHAIN` -> CHECK; that check's fixes take the same route |

1. **START**
   - **Reads**: the work record (request, reading, depth); `REQUIREMENTS.md` in either shape -- an unsplit
     document's `## 11. Technical Specification` as one unit, a split one feature by feature, old-shape feature
     sections included (Feature 005, Q67); `known-issues.md`; the work's `sources:` (Feature 001); the open `qa`
     entries, which come first (Feature 002); `.aid/knowledge/INDEX.md` and the documents it routes to, when a KB
     exists.
   - **What is already on disk is kept.** Detection (Feature 002, use (a)) shapes how far BREAKDOWN goes: existing
     stanzas and task files are kept and BREAKDOWN drafts only what the requirements still need. An old plan is not
     converted; its checklist is generated on the first render (The plan).
   - **A change after Planning** goes straight to REVISE: a call from another skill, or a typed start on a work
     whose phase is already past Planning, arrives here first (FR-20, Feature 002).
2. **BREAKDOWN** -- the tasks, their dependencies and their deliveries. The agent proposes; the user disposes.
   - `aid-architect` (clean context, tiered by `agent-dispatch-tiering.md`) writes every task file and the plan's
     stanzas from the requirements, the KB, the code and `known-issues.md` -- delivery by delivery on a large work,
     with `step_detail: 'breakdown: delivery-002'` -- and returns its open points; it never asks the user (Feature
     002). The main conversation then runs `derive-waves.sh --plan`.
   - **Atomic tasks**: each fits one agent session, has one type, is one reviewable unit, and cites at least one
     criterion. The eight types, their default criteria and the type-separation rule move from `aid-detail`
     unchanged; RESEARCH covers an unknown the design left open.
   - **Deliveries (Q72)**: one delivery for a work that does not split, one per feature for a work that splits.
     More only when a part must be checked before the rest can be built (a data migration, say). Each extra
     delivery adds a building milestone, so it is proposed as one question with its reason in `full`, and recorded
     `Assumed` in `lite`, for the confirmation before building to cover. A delivery is never split by layer or by
     size.
   - **No new design decisions.** A choice that would change the technical part (a library, an interface, a data
     shape) is not taken here: it is a `CALL` to `/aid-specify` REVISE with the reason (Feature 005), returning to
     this step. Small planning choices (order, grouping, task size) are the agent's, recorded `Assumed`.
   - **Ask only what blocks** a task or a dependency; with Feature 001's five items present nothing is asked.
     Questions follow the protocol, grouped by subject (deliveries, tasks, order), most important first;
     `step_detail` names the subject.
3. **CHECK** -- one graded `aid-reviewer` pass over the plan, every task file and `REQUIREMENTS.md`, in a clean
   context, at a tier no lower than the drafting architect's. Ledger `.aid/.temp/review-pending/<work>-plan.md`,
   7 columns, under `### What to report` (FR-21). It reports:
   - a requirement or criterion that no task serves, or a criterion no delivery lists (or one listed twice);
   - a task that cites no criterion, mixes types, or cannot be built from what it says;
   - a malformed graph: `derive-waves.sh --plan --check` exiting 2 (cycle, undefined task, dependency on a later
     delivery's task);
   - a delivery that breaks Q72's rule or lacks its stanza lines, or a task a later task needs that does not exist;
   - a conflict with the KB, the code, the technical part or a user's answer; a known issue the plan ignores;
   - on cycle 1, the cross-document contradiction pass (Guard 2), once per work.

   Wording, headings and the checklist's own layout are not findings.
   - **Grade**: `grade.sh` on the ledger against the global `minimum_grade`, recorded with `--review` (Feature
     005's work mode). Below the bar, BREAKDOWN fixes the rows, each fix scoped to its row, and CHECK runs again.
   - **After three rounds below the bar**, the same rule as Feature 005's CHECK (Q69): per open row, *fix it*,
     *accept it as is* (`Accepted` in the ledger, the choice in its Evidence cell) or *keep reviewing*.
   - It runs at every depth.
4. **APPROVE**
   - **`full`** (Feature 002's `PLAN.md` row; Q73): the plan in chunks, one topic per chunk -- the deliveries first
     (what each delivers, its criteria), then each delivery's tasks by wave -- with the small decisions taken since
     the last approval in the same batch. One question: *approve and start building* (recommended) or *approve,
     build later*. The first is also the confirmation before building (Approvals): recorded `category: Approval`,
     `covers: PLAN.md; confirmation before building`; the second `covers: PLAN.md`, and the confirmation is then
     asked by `/aid-execute` when building starts. A change the user asks for reopens as a question, goes back to
     BREAKDOWN, then CHECK.
   - **`lite`**: no stop. The plan is approved by `/aid-execute`'s confirmation before building, the work's one
     approval (Feature 007).
5. **FINISH**
   1. **`--plan-sync`** (Work state): every delivery and task gets its `Pending` entry, and the checklist is
      rendered.
   2. **The KB call** (Q68): the approval follows `skill-steps.md`'s KB call on confirmation (Feature 005) -- when it
      confirms an `Assumed` entry holding a decision of reach `project` (a `Specification change` from a revision
      made during Planning, say), the one `CALL` to `/aid-kb-update` carrying every such decision, returning here.
      Planning itself takes no `project` decision (BREAKDOWN), so nothing else calls. In `lite` there is no approval
      here, and the confirmation before building makes the call (Feature 007).
   3. **`PASS`**: `--handoff --to aid-execute --step <its entry step> --returns no --phase Building --why 'plan
      approved'` (`lite`: `'plan written'`), and `aid-execute` starts in the same turn (FR-8). After *approve,
      build later* the same hand-off is written but `aid-execute` is not started: the work is paused
      (`pause_reason: 'Plan approved; building not started'`), and the user is told in one line how to start.

**Changing the plan after Planning -- REVISE.** A plan is a hypothesis too (decision D3).
- **Entry**: a `CALL` from `/aid-execute` (a task finds the plan wrong; a requirements revision changed what tasks
  serve -- What other features must provide), with the reason in `--why`; or the user asking to change the plan of a
  work already past Planning, which is a typed start. Both land at START, which goes on to REVISE. No new work.
- **REVISE**: scope the change (the deliveries, tasks and ids it touches), edit the task files and stanzas, run
  `derive-waves.sh --plan`, and save `step_detail: 'revise: <what>'`. A task already `Done` is never edited or
  removed: a change to what it built is a new task. A started task is never removed.
- **CHECK**: the same pass, scoped to the changed task files, the tasks that depend on them and the changed stanzas.
- **APPROVE** in a revision, mirroring Feature 005's (Q62, Q70):
  - a change to the deliveries -- a delivery added or removed, what one delivers, or which criteria it lists:
    - `full`: one approval at once, recorded `category: Approval`, `covers: plan change`;
    - `lite`, before the confirmation before building: recorded `Assumed`, `category: Plan change`, part of what
      that confirmation covers;
    - `lite`, once the confirmation is recorded: one approval at once, as in `full`.

    During Building such an approval is a real blocker (FR-6), not a milestone;
  - a task-level change (a task added, split or merged, a dependency or a scope changed): no stop. Recorded
    `Assumed`, `category: Plan change`, confirmed in the batch of the work's next approval -- during Building, the
    next milestone (Feature 002).
- **FINISH** in a revision: `--plan-sync`, then the KB call as above for an approval at once; then `HALT`, which
  returns an open call, or, after a typed start, `PASS` back to the skill that drives the work's phase, at its entry
  step, without `--phase` (as Features 003 and 005 do).

##### 4. Work state

**One file per work (FR-12, Q34).** The per-delivery and per-task files existed so that two delivery branches never
wrote one file; one branch per work (FR-6, Q5) removes the reason. Waves are not stored. The planning part of the
work file (block style, Feature 002; three levels at most):

```yaml
# [W] one entry per delivery of PLAN.md, keyed by its id
#   state: Pending | Executing | Gated | Done | Blocked
deliveries:
  delivery-001:
    state: Pending
    updated: '2026-10-20T10:00:00Z'
    gate_tier: Small
    gate_grade: Pending
    gate_timestamp: --
    block_reason: --
    block_artifact: --
    issue_list: --
# [W] one entry per task, keyed by its id (shape unchanged)
#   state: Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
tasks_lifecycle:
  task-001:
    state: Pending
    review: --
    elapsed: --
    notes: --
    display_name: --
```

- **`deliveries`** -- new. `state` starts `Pending`; the building values stay today's until Feature 007 settles them.
  `issue_list` holds the delivery gate's issues as one text value (the readers' three-level limit), as
  `quick_check` already does for a task.
- **`tasks_lifecycle`** -- kept, with today's fields and its `quick_check` text value. It is the home of every task's
  state on every work, no longer only on a lite one.
- **Gone from the template**: `pipeline.path` (replaced by `intent.depth`, Feature 002), the top-level
  `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`, `delivery_lifecycle` and `delivery_gate`. `qa` is
  the work's only question record (Feature 002, KI-003).
- **`qa` entries this skill writes** (Feature 002's shape): the planning questions by subject; `Approval`, with
  `covers` `PLAN.md; confirmation before building`, `PLAN.md` or `plan change`; `Plan change` (`Assumed`).

**Writer** -- `writeback-state.sh` keeps Feature 002's lock, quoting, atomic rename and exit codes.
- **One target**: `--task-id NNN --field F` and `--task-id NNN --findings` write `tasks_lifecycle.task-NNN.*`;
  `--delivery-id NNN --lifecycle`, `--gate-field` and `--block` write `deliveries.delivery-NNN.*`; all in the work
  file, resolved like every work write (`AID_STATE_FILE`). The command lines do not change, so today's
  `aid-execute` and shortcut engine calls keep working; `--delivery-id` beside `--task-id` is accepted and has no
  effect. The nested-layout resolution, layout detection and the `AID_TASK_STATE_FILE` /
  `AID_DELIVERY_STATE_FILE` overrides go.
- **`--lifecycle`** accepts `Pending | Executing | Gated | Done | Blocked`; `Pending-Spec` and `Specified` exit 4.
- **`--plan-sync`** -- new, one locked write. It reads the task files (ids, and each one's delivery from Source) and
  the plan's stanzas (delivery ids; from Source alone when there is no plan), adds a `Pending` entry for every
  delivery and task that has none, and sets `Canceled` on a `Pending` task whose file is gone. A task file gone
  for a task in any other state exits 4 and writes nothing.
- **The re-render**: after `--plan-sync`, and after every task or delivery state write, when the work has a
  `PLAN.md`, the writer runs `derive-waves.sh --plan` under the same lock. It computes the checklist first and writes
  both files only if that succeeds; a malformed graph writes nothing and exits **11** (new, in the header), and the
  skill stops as Feature 002's fail-closed rule says. Rationale: building on a broken graph is the failure to avoid,
  and a plan is never left showing stale state.
- **Gone**: `--create --path`, the `"Pipeline Path"` field.

##### 5. Components

**`/aid-plan` description and guide line** (Feature 001's shape; final text set at build):
- `description:` "Break a work's requirements into small tasks with their dependencies, grouped into deliveries, and
  keep the plan as a checklist. Use when requirements are ready to plan, or when a plan must change."
- Skill-guide line, within SG-03's limit: `` - `/aid-plan` -- break the requirements into tasks and deliveries; before building ``
- The `/aid-detail` line goes, so SG-02 still matches `canonical/skills/` both ways.

**Approvals (Q73)** -- `skill-steps.md` § When approvals happen keeps its rows; one rule is added under the table:
"In `full`, when `/aid-plan` passes straight to building, its `PLAN.md` approval is also the confirmation before
building (M11, M12): recorded once, `covers: PLAN.md; confirmation before building`. `/aid-execute` then asks only
the per-wave stop choice, as a follow-up question, not an approval." The revision approvals are `/aid-plan`'s,
stated in `revise.md`, like Feature 005's.

**The shortcut engine** (until Feature 009): its PLAN and DETAIL states keep writing task files on a work with no
plan, but seed state with `--plan-sync` (no direct edit of a removed key, no `Specified`). Its works pass
`--depth lite` to the gate.

**`aid-deploy`**: it reads each delivery's state from `deliveries`, each task's from `tasks_lifecycle`, and the
delivery names from the plan's stanzas. Its `deploy` key and its steps are unchanged.

**Dashboard** (both readers, kept equal by the parity tests; FR-12, AC-41):
- **One layout**: tasks from `tasks/task-NNN/DETAIL.md` (title, type, delivery from Source, dependencies), task cells
  from `tasks_lifecycle`, delivery cells from `deliveries`, delivery names from the plan's `### delivery-NNN:`
  headings (today's `_parse_plan_delivery_titles`). Lanes are derived per delivery from the task files, extending
  today's `_derive_lanes_from_details` and its Node twin to group by delivery; the `wave-map` parse
  (`parse_execution_graph`) goes.
- **Gone**: `_detect_hierarchy`, `_read_work_hierarchical`, `_detect_flat` and `_declared_work_path` (one layout),
  `parse_task_state_md`, the delivery-file parse and the merge of delivery `qa` (Feature 002).
- **An old-layout work** -- a `deliveries/` folder, a top-level `delivery_state`, or a `pipeline.path` -- is not
  parsed: the readers set `layout_status: old` (detection lines inside `legacy-layout: begin` / `end` markers), and
  the card says "This work uses an older layout: run `aid update` in this project".
- **Work fields**: `depth` (from `intent.depth`) and `phases` (from `intent.phases`) replace `work_path`; `features`
  goes. `_ser_work` and `reader.mjs` pass them on.
- **`home.html`**: the badge shows the depth ("Full" / "Lite"); the path line becomes "{Full|Lite}: N deliveries ->
  M tasks (K done)", "[planning]" before any task exists, with no feature count; the features disclosure goes.
  The stage rail is Feature 002's, one per work from its `intent.phases` (Q75).
- The record warning (Feature 002) still shows on a migrated work whose type was left empty (Q74), until its first
  resume.

**Kept invariant**: `/aid-plan` writes only `PLAN.md`, the task files and, through the writer, the work file. It
changes `REQUIREMENTS.md` only through `/aid-specify` and a KB document only through `/aid-kb-update`.

##### 6. What other features must provide

| Feature | Must provide | Waiting on it |
|---|---|---|
| 007 | `aid-execute` reads tasks, dependencies and delivery membership from the task files (its graph scripts through `derive-waves.sh --from-tasks`, wave milestones through the same sort) and state from `tasks_lifecycle` and `deliveries`; its `pipeline.path` detection and full-path branches go. Its confirmation before building: after a recorded `covers: PLAN.md; confirmation before building` it asks only the per-wave stop choice; otherwise (`lite`, or *approve, build later*) it is the approval. A task that finds the plan wrong makes a `CALL` to `/aid-plan` (REVISE); so does a return from `/aid-specify` REVISE that changed what tasks serve. The delivery gate's `delivery-NNN-issues.md` log and `--append-issue` fold into `deliveries.<id>.issue_list`, so no delivery document remains (AC-19). Its entry step is named `START`, the step the migration writes for an old Execute work. Its `PL-04` row on the shared exempt list goes | `006-06`, `002-08`, `002-09` |
| 009 | The shortcut engine's PLAN and DETAIL states go, and with them its `PL-06` mark on the shared exempt list; its action skills reach `/aid-plan` through `/aid-specify` | -- |

**Owed to this feature by Features 001-005, and where each is met:**

| From | Owed | Met in |
|---|---|---|
| 001 | The final place of `intent:` and `sources:` in the single layout | Work state (top-level keys, beside the planning part) |
| 001 | `ticket_ref` at every level becomes a `sources:` entry, bash and PowerShell giving the same output | Migration |
| 002 (Q34) | The planning part of the work file; no delivery or task state files; the single migration | Work state; Files and layout; Migration |
| 002 | `--create --path` and `pipeline.path` go (replaced by `intent.depth`) | Files and layout; Work state; Migration |
| 002 | Every old work's record filled, phase names rewritten, delivery `qa` moved, then the gate's legacy block removed | Migration |
| 002 | The readers stop merging delivery `qa`; the record warning on unmigrated works | Components (Dashboard) |
| 002 | AC-28 rows for `aid-plan`, `aid-detail`, `aid-deploy`; samples `002-08`, `002-09` | Testing |
| 003 | The idea/design and describe legacy rows; old `interview:` keys | Migration |
| 004 | The work-state conversion joins format 6 (no format 7); the KB create/update legacy row | Migration |
| 005 | `aid-plan` reads both document shapes; unsplit tasks cite ids and no feature | Flow (START); The plan and the task file |
| 005 | `interview`, `features`, `review_history` dropped; old Define and Specify records filled | Migration |
| 005 | The `PLAN.md` approval applies the KB call on confirmation | Flow (FINISH) |
| 005 | The reads of `features` go: `aid-plan` Check 2's `Ready` gate, `aid-detail`'s "Spike Needed" | Files and layout; The task file |
| 005 | The dashboard's feature count follows the plan model | Components (Dashboard) |
| 005 | Guard 2's `aid-plan` row; SC10's review sites | Files and layout; Migration (Suites) |
| 005 | `005-07` past Specification, `005-13` | Testing |

##### 7. Risks

- **`aid-execute` is Feature 007's** (Q67's precedent). Until Feature 007 lands, a work planned by the new `/aid-plan`
  cannot be built by today's `aid-execute`: with a `PLAN.md` present, its flat path reads the plan's top-level
  `## Execution Graph`, which the checklist replaces. No bridge is built: no release ships between the two features
  (§7 Constraints 1), and the samples that build wait on the deferred list.
- **The PowerShell twin of the migration** restructures work state byte for byte, PowerShell 5.1-safe and ASCII, in
  every worktree. Its fixtures are written first and run in the Windows lane.
- **Removing the nested layout** reaches many suites and fixtures (Migration, Suites); `migrate-work-hierarchy.sh`
  stays, its output now feeding the format-6 step.
- **A work checked out after the migration ran** keeps its old layout. `aid update` runs the migration on every
  call, and its steps are idempotent, so the gate's and the dashboard's old-layout line names that command.
- **The re-render** changes `PLAN.md` with every task transition; it is the work's own file. A hand edit inside the
  checklist markers is overwritten -- the template says so.

##### 8. Migration

| Old | New |
|---|---|
| `/aid-detail` | `/aid-plan` writes the tasks too; say what you want changed in the plan |
| `/aid-plan --reset`, `/aid-detail --reset` | Ask for the plan to be changed; `/aid-plan` revises it |
| `deliveries/delivery-NNN/` folders and their state files | One `STATE.yml` per work; the plan's checklist shows progress |

- **Release notes**: the rows join the old -> new table (AC-24), drafted in `.aid/knowledge/backlog.md` § Next
  Release. No stubs (M1).
- **Installed projects**: `aid update` removes `aid-detail`, the deleted references and templates through the
  install manifest (decisions.md § D9).
- **Format 6 -- the work-state step** (Feature 004's format; no format 7): `_aid_migrate_repo`'s CONVERT-STATE step
  and its PowerShell twin gain it, run after the format-4 conversion (`migrate-work-hierarchy.sh` first, as today).
  It reaches every work `STATE.yml` in the main folder and in each worktree `git worktree list` registers, as
  Feature 004's parent-branch step does. Bash and PowerShell give byte-identical output; running it again changes
  nothing.
  - **Nested works** (a `deliveries/` folder):
    - each `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` moves to `tasks/task-NNN/DETAIL.md`; a task id found
      twice stops the step for that work, with a warning and nothing changed;
    - each task file's cells become `tasks_lifecycle.task-NNN`, each delivery file's become
      `deliveries.delivery-NNN` (`Pending-Spec` and `Specified` -> `Pending`; `delivery_gate.issue_list` -> one
      text value);
    - each delivery's `qa` entries are appended to the work's `qa` under the next free ids, their `context` opening
      with the old place (`(delivery-002 Q3)`);
    - the per-unit state files are deleted, then the folders they leave empty. A file the step does not know (an old
      `BLUEPRINT.md`, say) is kept, with a warning naming it: nothing is dropped.
  - **Old lite works**: `delivery_state`, `gate_*`, `delivery_lifecycle` and `delivery_gate` become
    `deliveries.delivery-001`.
  - **Every work**:
    - every `ticket_ref` (work, delivery, task) becomes a `sources:` entry -- `ref`, `kind: ticket`, `added` the
      work's `started`, `phase: --`, `effect: 'from ticket_ref (<level>)'` -- one per distinct ref;
    - `intent.depth`, when missing, takes `pipeline.path`'s value (Q11); then `pipeline.path` goes;
    - `interview`, `features` and `review_history` go (Feature 005);
    - the old phase names are rewritten (Feature 002's mapping);
    - **the record** of every open work whose resume fields are missing or incomplete -- `active_skill` and `step`,
      by `--check`'s field rules (Feature 002). An empty type, left on purpose for the one resume question (Q74), does
      not make the record incomplete for the fill, so a work an earlier run filled is skipped on every later run. A
      work with complete resume fields -- every work `--create` made -- is never touched, since its record is the
      only resume source and the record `--create` wrote wins. So only old phase names reach the fill. `active_skill`
      and `step` are decided from what is on disk, first match wins. The template's default `phase: Describe` is
      kept by every skill that never sets a phase, so only a phase some pipeline step moved is trusted:
      1. **A work halted at the shortcut approval** (Feature 002's halted-Lite row: `lifecycle:
         Paused-Awaiting-Input` and `delivery_state: Specified`) -> `/aid-execute`, before any phase row, so its
         `Detail` phase cannot catch it;
      2. **an old `active_skill: aid-deploy`** -> `/aid-deploy`, whatever the phase, as the gate orders it today, so
         an interrupted deploy at `phase: Execute` resumes in deploy;
      3. **a phase other than the default** (anything but `Describe`, and not missing, `--` or `Deploy`) decides:
         `Define` or `Specify` -> `/aid-specify`; `Plan` or `Detail` -> `/aid-plan`; `Execute` -> `/aid-execute`
         (Feature 002's `delivery_state` rows are Execute rows);
      4. **phase `Describe`**: initiator `aid-describe` -> `/aid-specify`; any other initiator -> the initiator rows of
         Features 003-005 (idea and design works -> `/aid-brainstorm`, the deleted KB `create` / `update` skills ->
         `/aid-kb-update`); with no row, the old `active_skill`, else the initiator itself, when that skill still
         exists (an `aid-research` or `aid-review` work resumes in its own skill);
      5. **phase missing, `--` or `Deploy`**: the old `active_skill` (`aid-define` -> `/aid-specify`, `aid-detail` ->
         `/aid-plan`, a skill that still exists -> itself), then the initiator rows as in 4.

      The skill is written at its entry step: `START` for the rebuilt skills (`aid-execute` included, Feature 007),
      `IDLE` for `aid-deploy`; each skill's START keeps what is on disk. The initiator otherwise serves only the type
      (below). A finished work gets no record (Feature 002);
    - **the type (Q74)**: `intent.reading` is set only where the starting skill makes it certain -- `aid-fix` ->
      bug fix, `aid-refactor` -> refactor, `aid-document-*`, `aid-create-document`, `aid-update-document` ->
      document, `aid-deploy` -> operational, `aid-update-kb` and the KB `create` / `update` skills -> knowledge
      update. Otherwise it is left empty: the first resume's `--check` finds it missing, and recovery asks one
      confirmation question (Feature 002).
  - **Era marker**: STEP 0 DETECT is unchanged; the step runs on any work that still has a `deliveries/` folder, a
    top-level `delivery_state`, a `pipeline.path`, a `ticket_ref` or a dropped key.
- **The gate's legacy block** goes once the step exists (its rows live on in the migration code). § 3b's recovery
  gains one check in its place: a work with an old layout is not repaired; the agent says in one line that the
  work predates this version and to run `aid update` in the project. `test-work-initiation-gate.sh` replaces its
  legacy-block fixtures with one old-layout fixture.
- **Old plans** keep their shape; their checklists appear on the first render (The plan).
- **Re-pointing**: every kept file under `canonical/`, and `dashboard/home.html`, that names `aid-detail`, a deleted
  template or reference, a `deliveries/delivery-NNN/` path or a per-task `STATE.yml` is re-pointed or reworded.
  Exempt: `canonical/aid/scripts/migrate/`, which reads old shapes. PL-02 and PL-04 enforce it. The sites today,
  beyond Files and layout: `downstream-worktree-entry.md` and `worktree-lifecycle.md` (their consumer lists),
  `connectors/consumption-protocol.md`, `reviewer-dispatch.md` (where a ledger may sit), `aid-monitor/SKILL.md` (its
  task-file paths), `complexity-score.sh` (its full-layout path), `aid-execute/SKILL.md` (its one `aid-detail`
  mention; the rest is Feature 007's, exempt from PL-04 until then), `aid-kb-build/references/elicit.md` (moved
  there by Feature 004), the comment in `dashboard/reader/derivation.py`.
- **Site**: `site/scripts/skills/` (roster, groups), `site/scripts/.skills-manifest.json`,
  `site/scripts/lib/flow-graph/` and their `__tests__`; pages and flows regenerated by `site/scripts/gen-skills.mjs`.
- **Lists other features own** -- each changes in the same commit as the skill it concerns:
  - **Deferred list** (`tests/conversation/deferred.tsv`): the `skill:aid-plan`, `skill:aid-detail` and
    `skill:aid-deploy` rows go (covered by `006-01` and `006-07`, or gone with the skill); `005-13` runs now and
    `005-07`'s checks run on through Planning; `002-08` and `002-09` wait only for Feature 007; this feature's
    deferred sample is added.
  - **Description exempt list** (SG-04): the `aid-detail` row goes, and `aid-plan`'s if it has one.
  - **SS-13** finds the rewritten brief by its glob; `aid-detail`'s goes with its skill.
  - **Shared exempt list** (`tests/canonical/skill-steps-exempt.tsv`): the `shortcut-engine.md` row's `checks` gain
    `PL-06` (owner Feature 009); a new row, `aid-execute`, checks `PL-04`, owner Feature 007. SS-14 (b)'s template
    exceptions lose the two deleted templates.
- **Suites**:
  - `test-scoped-review-cycles.sh`: SC10's plan and detail sites become `aid-plan/references/check.md`.
  - `test-writeback-state.sh`, `test-disjoint-merge.sh`, `test-delivery-gate-aggregate.sh`,
    `test-executor-graph-flat-plan.sh`, `test-lite-work-end-to-end.sh`, `test-derive-waves.sh`,
    `test-work-state-template.sh`, `test-connector-consumption-linkage.sh`, `test-ticket-retirement-structural.sh`,
    `test-downstream-worktree-entry.sh` and the dashboard reader, server and parity suites (hierarchy and
    `wave-map` fixtures among them) follow the single layout; an old nested fixture stays where it now checks the
    old-layout diagnosis.
  - `test-state-review-surface.sh`: SR17's `aid-detail` brief path is retired (the skill is gone); `aid-plan`'s
    rewritten brief stays covered; its old-shape state-file fixtures stay, still checking that state files never
    reach a review surface.
  - `test-pipeline-status-walkthrough.sh`: the `aid-plan` rows of A1, M4 and B1 re-point to `references/start.md`
    and `breakdown.md` with phase `Planning`; the `aid-detail` rows are retired (the skill is gone).
  - `test-task-state-transitions.sh`: its fixture is converted to the single layout (no `pipeline.path`, no
    top-level `delivery_state`; a `deliveries.delivery-001` entry), so the readers surface task state again.
  - `test-producer-completeness.sh`: its nested `deliveries/delivery-001` fixture is converted to the single layout,
    and the expected null lane is produced by a dependency cycle in the task files (lanes are derived from them, and
    a cycle yields none) instead of by removing `wave-map` blocks.
  - `test-artifact-discipline.sh` AD13 ceilings drop to the new measured counts.
  - Removed assertions go to `tests/coverage-accepted-removals.tsv`; `tests/coverage-rehome-allowlist.tsv`,
    `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv` are re-recorded.
- **User documentation** waits for the final pass (Q40, AC-45). The only edit now: the numbers
  `test-doc-counts.sh` asserts.
- **KB** (no work ids):
  - `artifact-schemas.md` (the single layout, `deliveries`, `tasks_lifecycle`, the plan and the task file; the
    delivery and task state files and the derived views go);
  - `pipeline-contracts.md` and `architecture.md` (Plan and Detail become one Planning row; the work layout; the
    loops that reach the plan now reach `/aid-plan` REVISE);
  - `domain-glossary.md` (delivery, wave and the plan checklist; Detail and the stored execution graph go);
  - `capability-inventory.md`, `module-map.md`, `project-structure.md`, `quality-gates.md` (one plan check replaces
    the plan and detail gates and the per-delivery review), `test-landscape.md` (the new suites);
  - `tech-debt.md`: W5-5's task-state half and SY-5, SY-6 narrowed (their delivery and task sites gone);
  - `decisions.md` gains "one state file per work; the plan is a generated checklist of deliveries, derived waves and
    atomic tasks whose task files are the only source". It **amends D29**: a delivery is still a stanza of the plan,
    but its criteria cite ids, and its task list and graph are generated -- marked in the summary table and in
    D29's section.
  - Then `INDEX.md` is regenerated and `kb.html` rendered by the script (Feature 004).

##### 9. Testing

Per NFR-T (Q35): unit tests and static checks now; a sample that needs a later feature waits on the deferred-tests
list.

**Static checks -- `tests/canonical/test-plan.sh`** (picked up by `tests/run-all.sh`; added to the suite list of
`.github/workflows/installer-tests.yml`):

| Group | Asserts |
|---|---|
| PL-01 | `canonical/skills/aid-detail/`, `delivery-state-template.yml`, `task-state-template.yml` and `canonical/aid/templates/delivery-plans/` are absent; `plan-template.md` exists; `aid-plan`'s new references and its brief exist, its deleted references do not |
| PL-02 | `aid-detail` is named by no kept file under `canonical/`, nor by `dashboard/home.html`, outside `canonical/aid/scripts/migrate/` |
| PL-03 | `aid-plan`'s step table has START, BREAKDOWN, CHECK, APPROVE, FINISH and REVISE; FINISH advances by `PASS` and `finish.md` names `aid-execute`, `--phase Building`, `--plan-sync` and `aid-kb-update` with `--returns yes`; `approve.md` names `confirmation before building`; `revise.md` names `plan change` and `Plan change`; `check.md` names the three choices after three rounds and `Accepted` |
| PL-04 | One layout: no tracked file under `canonical/skills/`, `canonical/aid/templates/` or `canonical/aid/scripts/` (except `migrate/`), nor `dashboard/home.html`, `dashboard/reader/*.py`, `dashboard/server/*.mjs` or `dashboard/server/*.py` outside `legacy-layout` markers, names `deliveries/delivery-`, a per-task `STATE.yml`, `AID_TASK_STATE_FILE`, `AID_DELIVERY_STATE_FILE`, `pipeline.path`, `Pipeline Path` or `Spike Needed`; the dashboard files also name no `work_path`. Files of entries on the shared exempt list marked for PL-04 are skipped (`aid-execute`, owner Feature 007) |
| PL-05 | `work-state-template.yml` has `deliveries:` and `tasks_lifecycle:`, each with its `[W]` comment, and no `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`, `delivery_lifecycle`, `delivery_gate` or `pipeline.path`; `work-initiation-gate.md` has no `legacy-phase-map` block and names `aid update` in § 3b |
| PL-06 | No file under `canonical/skills/` or `canonical/aid/templates/` other than `aid-plan`'s writes task files in a state of its own: no `## State: PLAN` or `## State: DETAIL` heading, no `--plan-sync` call. Files of entries on the shared exempt list marked for PL-06 are skipped (`shortcut-engine.md`, owner Feature 009) |
| PL-07 | `skill-steps.md` § When approvals happen states the Q73 rule (`covers: PLAN.md; confirmation before building`); `reviewer-dispatch.md`'s Guard 2 site table names `aid-plan` CHECK and no `aid-detail` row; `reviewer-ledger-schema.md` names `<work>-plan.md` and no `/aid-detail` row |

**Unit tests**
- `tests/canonical/test-writeback-state.sh`: `--task-id` and `--findings` write `tasks_lifecycle` in the work file,
  with or without `--delivery-id`; the `--delivery-id` modes write `deliveries.<id>`; `--lifecycle Pending-Spec`
  exits 4; `--plan-sync` adds `Pending` entries, cancels a `Pending` task whose file is gone, exits 4 and writes
  nothing for a gone task in another state, and changes nothing on a second run; a state write re-renders the
  checklist; a malformed graph exits 11 with both files unchanged; no `PLAN.md`, no render; `--create --path` and
  `"Pipeline Path"` are refused; every file written parses through the dashboard reader with no warning.
- `tests/canonical/test-derive-waves.sh`: `--plan` writes each delivery's checklist and a second run is
  byte-identical; `--check` returns 0, 1, 2 and 3 for its four cases and writes nothing; a dependency on a later
  delivery's task, a cycle and an undefined task each exit 2 with the plan unchanged; a delivery with no stanza
  gets one appended; a dependency on an earlier delivery is met; every task line's link resolves to that task's
  `DETAIL.md` from the plan's folder; an old stanza's `#### Execution Graph` and `wave-map` are replaced and its
  authored lines kept; the marks follow the work file; `--from-tasks` output is unchanged.
- `tests/canonical/test-slice-requirements.sh`: both new Source forms slice as Feature 005 says; the old form still
  reads.
- `tests/canonical/test-work-state-migration.sh`, on throwaway fixtures (a main folder and a registered worktree): a
  nested work, an old lite work and a single-layout work convert to the expected file and tree; `ticket_ref` at each
  level becomes one `sources:` entry per ref; delivery `qa` lands under fresh ids with its old place; the dropped
  keys go and `intent.depth` takes `pipeline.path`; phase names are rewritten; the record follows each legacy row,
  the type only where Q74 says; a work started by `aid-describe` and now at `Detail` gets `/aid-plan` at START; an
  `aid-design-api` work and an `aid-create-roadmap` work, each at the default `phase: Describe`, get
  `/aid-brainstorm` and `/aid-kb-update`; an `aid-refactor` work halted at the shortcut approval with phase `Detail`
  gets `/aid-execute`; a work with `active_skill: aid-deploy` at `phase: Execute` gets `/aid-deploy`; a work with a
  complete record (made by `--create`) at `phase: Definition` keeps its record byte for byte; a duplicate task id and an unknown file each warn and change or drop nothing; a
  second run over these fixtures changes nothing, the records included -- also for a work whose type the first run
  left empty; bash and PowerShell give the same bytes, the PowerShell half in the Windows lane.
- `tests/canonical/test-work-initiation-gate.sh`: an old-layout work gets the `aid update` line and no repair.
- Dashboard: fixtures for a single-layout work at Planning (task files, no entries yet), at Building with two
  deliveries (lanes per delivery, delivery names from the plan), and an old nested work (`layout_status: old`, the
  card line); the depth badge and path line in `test_index_html.py`; the parity tests.

**Conversation samples -- `tests/conversation/samples/feature-006/`** (frontmatter `skills: aid-plan` unless named)

| Sample | Covers | Runs |
|---|---|---|
| `006-01-bug-fix-one-delivery` -- fixture: code, a KB, a `full` work at Planning with an approved unsplit `REQUIREMENTS.md`. Check: one delivery; every task file's Source names it and ids, no feature; `PLAN.md` holds the stanza and a checklist that `derive-waves.sh --plan --check` finds current; no `deliveries/` folder and no task state file; a `reviews` entry at or above the bar; one approval in chunks, recorded `covers: PLAN.md; confirmation before building`; a `handoffs` pass to `aid-execute` with phase Building. The checks stop at that pass | AC-19, AC-28 | now |
| `006-02-split-work-delivery-per-feature` -- a split document with two features. Check: two deliveries, each listing its feature's criteria once and the shared line in both; Source names the feature; every dependency points to the same or an earlier delivery | AC-19 | now |
| `006-03-lite-no-stop` -- a `lite` work at Planning. Check: no approval question; small decisions `Assumed`; entries `Pending` for every delivery and task; a pass to `aid-execute` | AC-19, AC-10 | now |
| `006-04-reshape-the-plan` -- a `full` work; at the approval the user moves a task to the other delivery and adds a dependency. Check: the task files changed, the checklist regenerated with the new waves, `--check` exits 0, CHECK ran again before the new approval | AC-19, AC-28 | now |
| `006-05-extra-delivery-for-a-migration` -- an unsplit work with a data migration. Check: a second delivery proposed as one question with its reason; on yes, two stanzas; on no, one | AC-19, AC-28 | now |
| `006-06-plan-change-during-building` -- fixture: a work in Building; a task finds a missing task. Check: a `handoffs` call to `aid-plan`, a new task file, a `Plan change` entry `Assumed`, no approval asked, the call returned | AC-19, AC-37 | deferred: Feature 007 |
| `006-07-deploy-selects-deliveries` (`skills: aid-deploy`) -- fixture: a single-layout work with one delivery `Done`. Check: the delivery offered from `deliveries`, its question follows the protocol, no `deliveries/` path read | AC-28 | now |
| `006-08-old-work-after-migration` -- fixture: an old nested work at phase `Detail`, started by `aid-describe`, with a delivery-level question and a `ticket_ref`, after `aid update`. Check: the work resumes at `/aid-plan` START with its task files kept; one confirmation question proposes its type; the delivery question is offered first; the ticket is in `sources:` | AC-19, AC-37 | now |

Feature 005's `005-13` runs now and `005-07` runs through Planning; Feature 002's `002-08` and `002-09` wait only for
Feature 007; Feature 001's `001-07-rich-ticket` runs again at this feature's end.

##### Criteria traceability

| Criterion | Where satisfied | How verified |
|---|---|---|
| AC-19 | The plan and the task file (a generated checklist of deliveries with their criteria, waves, tasks, dependencies and state; one task file with no state); Work state (one file; no delivery or task state file); Flow; Migration | PL-01, PL-04, PL-05, PL-06; `test-derive-waves.sh`; writer unit tests; `test-work-state-migration.sh`; `006-01` to `006-05`, `006-08`; `006-06` (deferred) |

### Feature 007 — Hands-Off Building with Built-In Verification and Simplification

- **Priority:** Must
- **Requirements:** §5 FR-1, FR-6, FR-11, FR-19
- **Criteria:** AC-26, AC-32, AC-33, AC-34

#### Description

`/aid-execute` carries out the plan's tasks and tests them: a task is done only when its tests pass, and the result shows the test outcome. It opens with the confirmation before building (where the per-wave option is asked); after that the user is involved only at the building milestones defined in FR-6 and for real blockers; each task, and each delivery as a whole, goes through verification, then a lighter simplification pass, then a scoped re-verification only when the simplification changed something (FR-19). Each work builds on its one worktree and branch; the per-delivery branches are removed. It runs the FR-6 milestone steps, including the hand-offs to the CI skill.

#### User Stories

- As an AID user, I want every task built and tested before it counts as done, so that what I approve at the end actually works.

#### Technical Specification

Serves FR-1 (the Building phase), FR-6 (the confirmation, the milestones, one worktree and one branch), FR-11 and
FR-19, and follows FR-7, FR-17, FR-18 and FR-20 as Features 001-006 define them. Maintainer decisions: Q5, Q19, Q21,
Q24-Q26, Q35, Q36, Q60, Q62, Q70, Q73, Q76-Q80. Paths are `canonical/` sources, rendered as in Feature 001. "The plan"
is a work's `PLAN.md`; "a task file" is `tasks/task-NNN/DETAIL.md`; "the work file" is the work's `STATE.yml`; "the work
branch" is the work's one branch; "the parent branch" is `pipeline.parent_branch` (Feature 004, Q60).

##### 1. Files and layout

| Change | Path | What |
|---|---|---|
| Rewrite | `canonical/skills/aid-execute/SKILL.md` | The Building phase skill, for the whole plan: its step table (see Flow), `skill-steps.md` and `question-protocol.md` cited, Feature 001's what/when `description:` (see Components), `argument-hint: "[the work to build, or what to change while building]"`. At most 120 lines. Goes: Check 1's work listing and its own worktree entry (the gate and the work record do both, Feature 002), the layout detection and every full/flat branch, Check 5's per-delivery branches, the state map and banners, `## Delivery Lifecycle` with its "merge to main", the pool dispatch, `## Impediments`, `## Ticket Suggestion` (a write-back is made only on request, Feature 001), the quality checklist. The plan-mode check stays, as one line |
| Create | `canonical/skills/aid-execute/references/` | `start.md`, `build.md`, `test.md`, `verify.md`, `simplify.md`, `next.md`, `delivery.md`, `final.md`, `milestone.md`, `blocker.md`, `finish.md`, `old-work.md` (Migration), `fix.md` (the FIX contract, below); `reviewer-brief.md` is rewritten, with `### What to report` (SS-13) and four modes: task, delivery, simplify, re-verify. Each at most 120 lines |
| Edit | `canonical/skills/aid-execute/references/task-type-rules.md` | Each type says which tests it writes and runs, and what counts as its tests when it writes no code (see Flow, TEST) |
| Delete | `canonical/skills/aid-execute/references/` `state-execute.md`, `state-execute-drilldown.md`, `state-review.md`, `state-fix.md`, `state-re-run.md`, `state-delivery-gate.md`, `reviewer-guide.md` | Replaced by the references above; the type review focus of `reviewer-guide.md` moves into the brief, and `state-fix.md`'s FIX contract (F1-F7: a finding is a class, its sweep trailers, the oracle run) moves unchanged in substance into `fix.md` |
| Create | `canonical/aid/scripts/execute/simplify-guard.sh` | The test-set check of SIMPLIFY (see Components) |
| Edit | `canonical/aid/scripts/execute/writeback-state.sh` | The building fields and states, `--full-suite`, `--feedback`, `--feedback-add`, `"Wave Stops"`, `"Planned Wave Stops"`; `--findings`, `--append-issue`, `--gate-field` and `--block` go (see Work state) |
| Edit | `dashboard/scripts/writeback-state.sh` (the deliberate fork) | The same task and delivery targets for its writes, and the same derived delivery state (Work state); it keeps `Deploy` |
| Edit | `canonical/aid/scripts/execute/derive-waves.sh` | `--from-tasks <work-dir> --delivery NNN`: the dependency table and wave block of one delivery, a dependency on an earlier delivery's task counted as met; without `--delivery` the output is unchanged (see Components) |
| Edit | `canonical/aid/scripts/execute/complexity-score.sh` | Reads the delivery's graph from `derive-waves.sh --from-tasks --delivery` output; the quick-check consult factor and `--quick-check-state` go; header re-pointed |
| Edit | `canonical/aid/scripts/execute/compute-block-radius.sh` | Without `--delivery-id`, a graph with several `### delivery-NNN` sections (the unscoped `derive-waves.sh --from-tasks` output) is read as one graph across deliveries -- task ids are unique in a work -- instead of exiting 5; `--delivery-id` keeps today's scoped mode; header re-pointed |
| Delete | `canonical/aid/templates/delivery-issues.md` | No delivery issue log (AC-19) |
| Edit | `canonical/aid/templates/work-state-template.yml` | The building part (see Work state) |
| Edit | `canonical/skills/aid-plan/references/revise.md` (Feature 006) | A given-up task: cancel it and its dependents, or replan them (see Flow, Real blockers; Work state, `--plan-sync --cancel`); a correction goes to the delivery Flow step 7 names and declares no dependency on a `Done` task (see Flow, Corrections are ordinary tasks) |
| Edit | `canonical/aid/templates/skill-steps.md` § When approvals happen (Feature 002) | One row, the corrections after the whole build, and one rule, questions during Building (see Components, Approvals) |
| Edit | `canonical/aid/templates/reviewer-ledger-schema.md` (the ledger-path table) | The `/aid-execute task-NNN` row becomes the four `/aid-execute` ledgers (see Flow) |
| Edit | `canonical/aid/templates/downstream-worktree-entry.md`, `worktree-lifecycle.md` | `aid-execute` leaves their consumer lists; § Composition with `aid-execute`'s per-task worktrees goes |
| Edit | `canonical/aid/templates/shortcut-engine.md` § State: APPROVAL-HALT and its lines naming `state-delivery-gate.md`, `delivery_gate` or `delivery_state` | The yes is recorded as the confirmation before building (see Components, The shortcut engine); the delivery lines name `deliveries`. The engine itself stays until Feature 009 |
| Edit | `canonical/agents/aid-developer/AGENT.md` | "IMPEDIMENT.md" becomes a blocker in its report -- evidence, options, recommendation -- which the main conversation raises (Feature 002: a sub-agent never asks) |
| Edit | `canonical/aid/scripts/config/read-setting.sh` | Its usage example names a key that is still read (`execution.max_parallel_tasks` has no reader left) |
| Edit | `canonical/aid/rules.md` § Skill guide | The `/aid-execute` line is rewritten (Components) |
| Edit | `dashboard/reader/models.py`, `parsers.py`, `reader.py`, `dashboard/server/reader.mjs`, `server.py` § `_ser_work`, `server.mjs`, `dashboard/home.html` | See Components, Dashboard |
| Edit | `bin/aid`, `bin/aid.ps1` | The building part of format 6's work-state step (see Migration) |
| Edit | every other kept file under `canonical/`, and `dashboard/home.html`, that names a deleted reference, `delivery-NNN-issues.md`, `IMPEDIMENT-task-NNN.md`, a per-delivery branch or the per-task worktrees | Re-pointed (Migration) |
| Create | `tests/canonical/test-execute.sh`, `tests/canonical/test-simplify-guard.sh`, `tests/conversation/samples/feature-007/` | See Testing |

##### 2. Flow

The plan's FINISH passes the work here with `--phase Building` (Feature 006); typing `/aid-execute` on a work at
Building is a resume, on another work a typed start (Feature 002). One run builds the whole plan, **one task at a time**
(Q76), in the order of the plan's waves, inside the work's one worktree and on the work branch. The depth is
`intent.depth`; with none recorded, `full` applies (Feature 002).

| Step | Reference | Worker | Advance |
|---|---|---|---|
| START | `references/start.md` (`references/old-work.md`) | main conversation | `ASK` -> START for the confirmation, then for the wave question; `CHAIN` -> BUILD; `CHAIN` -> DELIVERY, FINAL or MILESTONE when the plan already stands there |
| BUILD | `references/build.md` | the executor of the task's type | `CHAIN` -> TEST |
| TEST | `references/test.md` | main conversation | `CHAIN` -> VERIFY when the task's tests pass; `CHAIN` -> BUILD in a fix |
| VERIFY | `references/verify.md` (brief: `references/reviewer-brief.md`) | `aid-reviewer` | `CHAIN` -> SIMPLIFY when the grade passes; `CHAIN` -> BUILD in a fix; after three rounds below the bar, `ASK` per open row |
| SIMPLIFY | `references/simplify.md` | `aid-reviewer` lists; the executor applies | `CHAIN` -> REVERIFY when something changed; else `CHAIN` -> NEXT |
| REVERIFY | `references/verify.md` (re-verify mode) | `aid-reviewer` | `CHAIN` -> NEXT, after undoing the simplification when it fails |
| NEXT | `references/next.md` | main conversation | `CALL` to `aid-kb-update` when the KB check hits; then `CHAIN` by the routing rule (NEXT, below) -> BUILD, MILESTONE, DELIVERY or FINAL |
| DELIVERY | `references/delivery.md` | `aid-reviewer`; the executor for fixes and the simplification | `CHAIN` by NEXT's routing rule -> MILESTONE, or FINAL first for the last delivery |
| FINAL | `references/final.md` | main conversation; the executor and `aid-reviewer` for fixes | `CALL` to `aid-kb-update` when owed; `CHAIN` -> MILESTONE |
| MILESTONE | `references/milestone.md` | main conversation | `CALL` to `aid-monitor-pipeline` (collect, push); `CALL` to `aid-plan` for corrections, then `CHAIN` -> BUILD; `ASK` the approval, recorded with its `covers` (step 10); then `CHAIN` by NEXT's routing rule |
| FINISH | `references/finish.md` | main conversation | `PASS` to the close; in a correction call, `HALT` |

Any step may raise a **real blocker** (`references/blocker.md`): `ASK` -> the same step. `step_detail` always names the
task or delivery and where it stands (`'task-004: verify round 2'`, `'delivery-002: simplify'`).

1. **START**
   - **Reads**: the work record; the plan and every task file (id, type, delivery from Source, dependencies); state from
     `tasks_lifecycle` and `deliveries`; `REQUIREMENTS.md` through `slice-requirements.sh`, either shape (Feature 005);
     `known-issues.md`; the open `qa` entries, which come first (Feature 002); `.aid/knowledge/INDEX.md` and the
     documents it routes to, when a KB exists. `--plan-sync` runs first, so every task has its entry.
   - **The confirmation before building** (FR-6, M12; Approvals):
     - **Already recorded** -- an `Approval` entry answered yes whose `covers` holds `confirmation before building`
       (Feature 006's combined approval, Q73): nothing more is approved.
     - **Otherwise** (`lite`, a `full` work after *approve, build later*, or a doorway work, Components): START asks
       it. The plan and, in `lite`, the requirements are shown in chunks, most important first -- one short line for a
       small fix -- with the small decisions taken so far in the same batch (`Assumed` `Specification change` and
       `Plan change` included). The message says, when they apply, that the idea draft will be removed (Feature 003)
       and which `project` decisions will be recorded in the KB (Feature 005). Recorded `category: Approval`, `covers:
       REQUIREMENTS.md; PLAN.md; confirmation before building` in `lite`, `covers: confirmation before building` in
       `full`. Right after the yes: Feature 003's draft deletion and the KB call on confirmation (`skill-steps.md`).
     - **A change asked here**: a requirement or criterion -> `CALL` to `/aid-specify` (REVISE); a task or delivery ->
       `CALL` to `/aid-plan` (REVISE); on return, the confirmation is asked again. *Not now* pauses the work
       (`pause_reason: 'Waiting for the confirmation before building'`).
   - **The wave question** -- a follow-up question, not an approval, asked once (`wave_stops.choice` is `--`), and only
     when a delivery has more than one wave (otherwise every wave end is a delivery end, and `none` is recorded).
     Options: *no stop per wave* (recommended: the delivery and whole-build milestones stay), *a review per wave*, *a
     review and a pull-request update per wave* (offered only when the work branch has a remote). Recorded `category:
     Building`. With the choice, START saves the planned stops in `wave_stops.planned`: every wave end of each
     delivery but its last, from `derive-waves.sh --from-tasks --delivery` over the plan as approved (empty for
     `none`). It is written once, here, and never changes: corrections and `/aid-plan` REVISE never add to it, and a
     delivery added during building gets no wave stop, only its delivery milestone.
   - **The full-suite baseline** (Q79), once, before the first BUILD: the project's full suite runs on the starting
     commit (Components, Full suite); `full_suite.baseline` holds what passed and which tests already fail. When
     START finds a task already built and no baseline (an old work), it records `baseline: not taken`.
   - **What is already on disk is kept** (Feature 002, use (a)): `Done` tasks stay; an `In Progress` task goes on at
     BUILD, an `In Review` task at VERIFY; anything else goes by NEXT's routing rule (step 7), which reads no stored
     delivery state. An old work's per-delivery branches and per-task worktrees are handled first
     (`references/old-work.md`, Migration).
   - **A correction call** (a `CALL` from `/aid-monitor-pipeline`, What other features must provide): no confirmation
     and no wave question; `/aid-monitor-pipeline` has already added the corrections to the last delivery through
     `/aid-plan` REVISE, and NEXT's routing rule builds them (step 7).
2. **BUILD** -- for the next task whose dependencies are `Done`, lowest id first within its wave.
   - **Task state**: `In Progress` written at entry, before anything else (rules.md tracking discipline); the task's
     `base` (the commit before its first round) on the first round.
   - **The executor**: by type, as today -- `aid-developer` (IMPLEMENT, TEST, MIGRATE, REFACTOR, CONFIGURE),
     `aid-researcher` (RESEARCH), `aid-architect` (DESIGN), `aid-tech-writer` (DOCUMENT) -- in a clean context, tiered
     by `agent-dispatch-tiering.md`, with the dispatch protocol (`dispatch-protocol-checklist.md`). It receives the
     task file, the slice, `known-issues.md`, the KB documents the index routes to and its type's rules, and works in
     the work's worktree. It returns what it changed, its test files and test command, the small decisions it took
     (recorded `Assumed`, `category: Building`), and its open questions (never asked by it, Feature 002).
   - **A fix round** (from TEST, VERIFY, DELIVERY or FINAL) follows `references/fix.md` and is scoped to the failing
     tests or the ledger rows, with
     `step_detail: 'task-004: fix rows 2, 3'`.
   - **Commit**: each round ends with one commit on the work branch, `task-NNN: <title>` or `task-NNN: fix <rows>`,
     staging only the paths that round changed -- never `.aid/.temp/` or `.aid/works/` (the work folder is Feature
     008's, by the project setting); KB paths only through `kb-commit.sh` (Feature 004).
   - **Without git** -- the one rule for it: nothing is committed, and every `commit` field (a task's, a delivery's,
     an approval's) holds the name of the newest snapshot, numbered in order, so "newer than an approval" reads as
     with git. A snapshot of the project's files outside `.aid/` is taken under `.aid/.temp/execute/<work>/snapshots/`
     at the start of every round -- a task's build, fix and simplify rounds, and DELIVERY's fix and simplify rounds.
     The task's first snapshot is its `base` for VERIFY; the first snapshot of a delivery's first task is the
     delivery's `base` for DELIVERY; the snapshot taken at the start of a simplify round is what the undo restores and
     what `simplify-guard.sh --snapshot` compares against.
   - **What the executor finds**: an open question goes to `blocker.md` when the task cannot go on without it;
     otherwise the main conversation takes the executor's recommendation and records it `Assumed` (with `--answer`,
     state `Assumed`), confirmed at the next milestone like every small decision (Real blockers). A finding that the
     requirements are wrong (today's `wrong-assumption` and `architecture-conflict`) -> `CALL` to `/aid-specify`
     (REVISE); a missing task or dependency -> `CALL` to `/aid-plan` (REVISE); a fact the KB lacks (today's `kb-gap`)
     -> `CALL` to `/aid-kb-update`; each returns here.
3. **TEST** -- the main conversation runs the task's tests itself: the test files the executor wrote or that cover what
   it changed, with the command it named (AC-26). A task that writes no code (RESEARCH, DESIGN, DOCUMENT) runs the
   checks its criteria name (a link check, a render), or records `not applicable` with the reason, which VERIFY
   judges.
   - Pass: `tests` is written (`'passed 14 of 14'`) and the test files listed in
     `.aid/.temp/execute/<work>/task-NNN-tests.txt` for SIMPLIFY.
   - Fail: back to BUILD in a fix, with the failure output. The same failure after three fix rounds is a real blocker
     (the M7 limit, applied here).
4. **VERIFY** -- the review cycle (FR-19). Task state `In Review`, written before the reviewer is dispatched.
   - One graded `aid-reviewer` pass, clean context, at a tier no lower than the executor's (decision D6), over the
     task's diff (`base..HEAD`), the task file, the slice, the KB documents it touches and the test result. Ledger
     `.aid/.temp/review-pending/<work>-task-NNN.md`, 7 columns, under `### What to report` (FR-21). It reports a
     criterion not met, a test that does not exercise what it claims, a conflict with the KB or the technical part,
     a change outside the task's scope, and a known issue the task ignores. Wording and style are not findings.
   - **Grade**: `grade.sh` against `minimum_grade` (`read-setting.sh --skill execute`), recorded with `--review`
     (Feature 005's work mode) and in the task's `verify`. Below the bar: BUILD in a fix, TEST, VERIFY again.
   - **After three rounds below the bar**, Feature 005's rule (Q69), as a real blocker: per open row, *fix it*,
     *accept it as is* (`Accepted` in the ledger) or *keep reviewing*.
5. **SIMPLIFY** -- only after VERIFY passes, **once** per task (FR-19).
   - `aid-reviewer` in simplify mode, one pass, no grade, lists what can be simplified or cleaned without changing
     behaviour: duplication, dead code, needless indirection, over-engineering, clutter. Ledger
     `<work>-task-NNN-simplify.md`. No row: `simplify: no change`, on to NEXT.
   - The executor applies the rows it can apply without changing behaviour, touching no test file, in one commit
     `task-NNN: simplify`. Then the task's tests run again, and `simplify-guard.sh` checks that no file of the task's
     test list was changed, added or removed. A guard failure or a test that no longer passes undoes the
     simplification at once (below) -- it never changes behaviour.
   - Something changed: `simplify: changed`, on to REVERIFY.
6. **REVERIFY** -- only when the simplification changed something, scoped to the simplify commit's diff (re-verify mode,
   ledger `<work>-task-NNN-reverify.md`), graded against the same bar, recorded in `reverify` and with `--review`.
   - **Fails** (Q78): the simplification is undone -- `git reset --keep <the verified commit>`, which leaves every
     uncommitted file in place; without git, the simplify round's snapshot is restored (BUILD, Without git) -- and
     `simplify: undone` is recorded. No second round: no simplify/verify loop.
7. **NEXT**
   - `Done` is written only now: the tests passed, VERIFY passed, and REVERIFY passed or the simplification was undone
     (AC-26, AC-33). `commit` records the task's last commit; the ledgers are deleted.
   - **The KB check** (Feature 004): `kb-freshness-check.sh --doc <doc> --format tsv` for every KB document whose
     `sources:` the task's commits touched, plus the executor's report of a new module, dependency or convention. A hit,
     with a KB: one `CALL` to `/aid-kb-update` (`--why 'task-NNN built: <what>'`), which stamps against the task's
     commit and records its change `Assumed` for the next approval. With no KB, no call: the agent says once per work
     that the KB is not built (Feature 004, No KB: one rule).
   - **What comes next** -- the one routing rule. It runs at the end of NEXT, DELIVERY and MILESTONE, and when a call
     made from NEXT returns (a given-up task, Real blockers), so it holds in a live run as on resume.
     - **One principle: a result is valid only for the commit it records.** A delivery's `verify` (with the delivery's
       `commit`), `full_suite.result` (with `full_suite.commit`) and every milestone `Approval` (with its `commit`)
       are **stale** when a `Done` task in their scope has a commit they do not contain
       (`git merge-base --is-ancestor <task commit> <their commit>` fails; without git, a newer snapshot -- BUILD,
       Without git). The scope is the delivery for its `verify` and its approval; the whole work for `full_suite` and
       the `whole build` approval. A wave stop is never stale: it is asked once (rule 1). A `Canceled` task is closed
       and adds no commit. A milestone's approval is the newest `Approval` answered yes whose `covers` lists it.
     - **Inputs** -- only these: the task states and each task's `commit`, each delivery's `verify` and `commit`,
       `full_suite`, `wave_stops`, those approvals, and the wave stops' answered entries. **It never reads a stored
       delivery state**: that state is a display value the writer derives from the same facts (Work state), and no
       step writes it.
     - **Open and closed**: an open task is one neither `Done` nor `Canceled`. A delivery is **closed** when it has no
       open task and either all its tasks are `Canceled`, or its `verify` and its `delivery delivery-NNN` approval are
       both current; otherwise it is open. The current delivery is the lowest-numbered open one. A task added to any
       delivery -- a closed one, or one whose tasks were all `Canceled` -- simply makes it open again.
     - **First match**:
       1. a wave stop -- a pause inside a delivery's first build only, asked once: while the current delivery has no
          `verify` recorded (current or stale) and no `full_suite` result has ever been recorded -- a delivery's first
          build ends when DELIVERY first runs, the whole build when FINAL first runs -- N the furthest wave of the
          current delivery with every task of waves 1 to N closed, a later wave of the same delivery still holding an
          open task, `delivery-NNN/wave-N` on `wave_stops.planned`, and no answered entry (yes or a change) whose
          `covers` lists `wave delivery-NNN/wave-N` -> MILESTONE. A wave end a correction creates is never on the list,
          so it never stops. Once a wave stop is answered it is never asked again: the changes asked
          there, and the suggestions taken there, are corrections approved at the delivery milestone. At the delivery's
          last wave there is no wave stop: the delivery milestone covers it;
       2. an open task of the current delivery whose dependencies are `Done` -> BUILD;
       3. the current delivery with no open task, at least one `Done`, and its `verify` missing or stale -> DELIVERY;
       4. the current delivery with no open task, its `verify` current, and its approval missing or stale -> MILESTONE
          -- for the last open delivery, after FINAL when `full_suite` is missing or stale;
       5. no open delivery: `full_suite` missing or stale -> FINAL; else the `whole build` approval missing or stale ->
          MILESTONE; else FINISH.
     - **Corrections are ordinary tasks** (Q77), added by `/aid-plan` REVISE. A correction made at a milestone joins
       the delivery that milestone covers -- when it covers several, the last of them; at a whole-build-only milestone,
       or in a correction call (Feature 008), it joins the last delivery that has a `Done` task, never an
       all-`Canceled` one. It declares no dependency on a `Done` task -- what it corrects is already built -- so the
       wave graph places it in wave 1 unless it depends on another correction. Adding it reopens that delivery; once it
       is built, the rule above finds the results it made stale, so the delivery is verified again and the milestone
       that covers it is asked again. A wave stop is never asked again (rule 1), so the delivery milestone -- or the
       whole-build milestone that coincides with the last one -- approves it. A correction never creates a wave
       stop of its own, and no milestone is asked again with nothing new built in it.
8. **DELIVERY** -- the same sequence over the whole delivery (FR-19), before its milestone.
   - **Verify**: one graded `aid-reviewer` pass over the delivery's diff (`deliveries.<id>.base..HEAD`), its tasks, the
     criteria its stanza lists and the KB, at the tier `complexity-score.sh` gives (`tier`). Ledger
     `<work>-delivery-NNN.md`. It also reports what the tasks miss together: glue, naming across tasks, a criterion
     checkable only now. Every task's tests run together. Fixes are made by the executor, scoped to the rows, as in a
     task; three rounds below the bar ask per row, as in VERIFY. Rows the user accepts go to `issue_list`.
   - **Simplify**: once, for duplication across the delivery's tasks, with the same guard over every task's test list.
   - **Re-verify**: scoped to that commit, only when something changed; a failure undoes it (Q78).
   - Recorded in the delivery's `verify`, `simplify`, `reverify`, `tests` and `commit` -- the head its verification
     passed on (step 7); then on by NEXT's routing rule
     (step 7): its MILESTONE, or FINAL first for the last delivery.
9. **FINAL** -- once every task is `Done` or `Canceled`.
   - **The full suite** runs on the work branch's head (Components, Full suite). A failure absent from the baseline is
     the work's: fixed by the executor in a scoped round (`step_detail: 'full suite: fix <tests>'`), the suite run
     again, and the fix verified (re-verify mode) -- three rounds, then a real blocker. A failure already in the
     baseline is reported, not fixed (Q79). With `baseline: not taken`, every failure is shown at the approval, each
     with the agent's recommendation: a correction task, or report it as already present. The run that ends FINAL is
     recorded in `full_suite.result` with `full_suite.commit`, the head it ran on (step 7).
   - **Backlog and roadmap** (Feature 004): when the work's `sources:` name a `backlog.md` or `roadmap.md` item, one
     `CALL` to `/aid-kb-update` updates it as the document says, with a KB; none without one.
10. **MILESTONE** -- the FR-6 steps, one rule for every milestone (M10).
    1. **Collect**: when the work has a pull request (`pull_request`, Feature 008), a read-only `CALL` to
       `/aid-monitor-pipeline` adds the new review comments and pipeline results to `feedback`, and returns.
    2. **Corrections** (Q77): every `Open` entry of kind `bug`, `correction` or `pipeline failure` becomes a correction
       task -- one `CALL` to `/aid-plan` (REVISE, `--why 'corrections: F1, F3'`), recorded `Assumed` `Plan change`
       (Feature 006), in this milestone's delivery (step 7, Corrections are ordinary tasks) -- built through the task
       loop, BUILD to NEXT; the entry's state becomes `Task`. A `conflict`
       with the parent branch is not corrected here: it is shown, and `/aid-monitor-pipeline` resolves it when it
       pushes (Feature 008, KI-005). A `suggestion` or `comment` becomes a question in this milestone's batch, with
       options and a recommendation (FR-7).
    3. **The approval**: in chunks, most important first -- what was built since the last milestone (tasks, test
       results, verify grades, simplify outcomes), the corrections, the work's `kb_updates` since then, and the small
       decisions to confirm (`Building`, `Plan change`, `Specification change`, `KB change`) in the same batch. At the
       whole build it also shows the full-suite result against the baseline (AC-26). Recorded `category: Approval`,
       with `commit`, the work branch's head, and `covers` naming each milestone it approves, in these exact forms:
       `wave delivery-NNN/wave-N`, `delivery delivery-NNN` and `whole build`. Coinciding approvals are one (M11), so its
       `covers` lists each, separated by `; ` -- `delivery delivery-002; whole build; final result`; NEXT's routing
       rule reads these values. Right after the yes, the KB call on confirmation for any `project` decision it
       confirmed. A suggestion the user takes becomes a correction task, built after this approval.
       - **How an answer is recorded** -- Feature 002's protocol, as every approval in Features 004-006: the milestone
         question is written `Pending` with `--ask` (`category: Approval`, its `covers`) before it is shown, and the
         answer records it `Answered`, its value yes or the change asked. It is an approval -- it counts for `covers`,
         for `commit` and for a push -- only when the answer is yes. A delivery or whole-build milestone answered with a
         change becomes correction tasks, by step 2's route, and once they are built it is asked again: its yes is
         still missing, and DELIVERY runs first because `verify` is stale (step 7). A wave stop answered with a change
         is not asked again: its corrections are approved at the delivery milestone (rule 1). A rejected `KB change`
         reopens as a question (Feature 004).
    4. **The push** -- at a milestone that may push (every delivery and the whole build, and a wave when
       `wave_stops.choice` is `review-and-update`), when the work branch has a remote: one question, "Create or update
       the pull request now?", recommendation yes. Yes: a `CALL` to `/aid-monitor-pipeline` that pushes up to the
       approved `commit` and creates or updates the one pull request, and returns. No: nothing is pushed; the next
       milestone asks again.
    - Then on by NEXT's routing rule (step 7).
11. **FINISH**
    - **After the whole build**: `user_approved: 'yes'` (Feature 002), then `PASS` to the close -- `--handoff --to
      aid-monitor-pipeline --step <its entry step> --returns no --phase CI --why 'whole build approved'`. Until Feature
      008 lands, `/aid-orchestrate` runs the close minimum (Feature 001's phase table), as Feature 004's KB update does.
    - **In a correction call**: `HALT`, which returns to `/aid-monitor-pipeline`, which pushes.

**Real blockers** (`references/blocker.md`; FR-6, AC-32) -- the only interruptions besides the milestones:
- a question a task cannot go on without; a decision that conflicts with the KB (AC-5);
- three rounds below the bar (VERIFY, DELIVERY), or the same test failure after three fix rounds (TEST, FINAL);
- a KB-update question the change cannot go on without (Feature 004);
- an old work's diverging delivery branches or a leftover task worktree holding changes (Migration);
- an approval a revision needs at once: a requirement or criterion change once the confirmation is recorded (Feature
  005, Q62, Q70), a change to the deliveries (Feature 006).

Each of the first four is one question under the protocol, `category: Blocker`, importance high, with its options and
recommendation. The last is not a `Blocker` question: it is the revising skill's own approval, recorded as Features 002,
005 and 006 record it -- `category: Approval`, `covers: requirements change` or `plan change`. Either way `ASK` saves
the step and pauses the work (`lifecycle: Paused-Awaiting-Input`), the task keeps its state, and no further task runs
before the answer.

**A question that does not block** is not asked during Building. As Feature 002 does for every small decision, the
agent takes its own recommendation and records it `Assumed`, and the next milestone confirms it in its batch; a rejected
one reopens as an ordinary question. A skill that keeps the point out of its document until it is confirmed (Feature
004's KB update) waits for that confirmation. Between milestones only a real blocker is `Pending`, so a resumed
session asks only real blockers.

**A task that keeps failing** (TEST or VERIFY after three rounds, or a blocker about one task): the question offers
*retry*, with the user's guidance, or *give it up* -- *cancel it and what depends on it*, or *replan them* (with what
should be built instead). Giving up writes the task `Failed`, its dependents `Blocked` (`compute-block-radius.sh` over
the whole work's graph) -- their delivery then shows `Blocked` (derived, Work state) -- saves the step as NEXT, and
makes a `CALL` to `/aid-plan` (REVISE, `--why 'task-NNN given up: cancel'` or `'... replan'`), which returns to NEXT,
not to the TEST or VERIFY step it left; NEXT's routing rule then picks what comes next. REVISE cancels the task and
its dependents, or replaces the task and rewires the dependents, and its FINISH runs `--plan-sync --cancel` (Work
state): the cancelled tasks become `Canceled` and a rewired dependent goes back to `Pending`; NEXT's rule reads the
delivery from those task states. Cancelling every task of a delivery is a change to the deliveries, approved at once
(Feature 006). DELIVERY and FINAL count a `Canceled` task as closed.

**Changing the plan or the requirements during Building** -- the routes of Features 005 and 006, unchanged:
- a task-level plan change or a technical-only requirements change: no stop, recorded `Assumed`, confirmed at the next
  milestone;
- a requirement, criterion or delivery change once the confirmation is recorded: the revising skill's approval at once,
  recorded `Approval` (`covers: requirements change` or `plan change`), which pauses the build like a real blocker
  (above); before the confirmation in `lite`, recorded `Assumed` for it;
- a return from `/aid-specify` REVISE that changed what tasks serve: a `CALL` to `/aid-plan` (REVISE);
- on every return: `--plan-sync`, then the step it left, which re-reads the plan. A `Done` task is never edited
  (Feature 006): a change to what it built is a new task.
- A typed start of another skill comes back by `PASS` to START; a side idea from Building (Feature 003) by `HALT`, to
  the saved step.

**Control signals** (the dashboard's stop and finish, kept): at every step entry the work's `lifecycle` is re-read --
not `Running` stops the run before any dispatch -- and the current task's `.aid/.control/<work>/task-NNN.stop` is
checked -- present pauses the run before the task's next dispatch, until it is removed. No task state is written for a
pause, as today.

##### 3. Work state

The building part of the work file (block style, Feature 002; three levels at most). It extends Feature 006's planning
part:

```yaml
# [W] the per-wave stop chosen at the confirmation before building, and the planned stops saved with it
#   choice: none | review | review-and-update; -- until asked
#   planned: one text value, 'delivery-001/wave-1, delivery-001/wave-2'; -- when none
wave_stops:
  choice: --
  planned: --
# [W] the project's full test suite: the baseline at START and the run at the end
full_suite:
  command: --
  baseline: --
  baseline_commit: --
  result: --
  commit: --
# [W] review comments and pipeline results collected at milestones, newest last
#   kind: bug | correction | suggestion | comment | pipeline failure | conflict
#   state: Open | Task | Asked | Declined | Shown | Done
feedback: []
# [W] one entry per delivery of PLAN.md, keyed by its id
#   state (derived by the writer; shown, never read for routing): Pending | Building | Verifying | Approving |
#     Done | Blocked | Canceled
deliveries:
  delivery-001:
    state: Pending
    updated: '2026-10-20T10:00:00Z'
    tier: --
    base: --
    verify: --
    simplify: --
    reverify: --
    tests: --
    commit: --
    issue_list: --
    block_reason: --
# [W] one entry per task, keyed by its id
#   state: Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
#   simplify: changed | no change | undone; --
tasks_lifecycle:
  task-001:
    state: Pending
    base: --
    verify: --
    simplify: --
    reverify: --
    tests: --
    commit: --
    elapsed: --
    notes: --
    display_name: --
```

A `feedback` entry holds `id` (`F<n>`), `at`, `kind`, `ref` (the comment or pipeline run), `summary`, `state` and `link`
(the task or question it became, or `--`).

- **Task states** keep the closed list and its meaning: `In Progress` from BUILD (and in a fix round), `In Review` from
  VERIFY through REVERIFY, `Done` at NEXT, `Failed` only for a task given up; `Blocked` is assigned to the dependents of
  a failed task, never self-written (rules.md); `Canceled` for a given-up task and its dependents once `/aid-plan`
  REVISE cancels them.
- **Delivery states** settle what Feature 006 left open, as a display value only: the writer derives `state` and
  `block_reason` at every write, from the facts NEXT's routing rule reads, first match -- `Canceled` (every task
  `Canceled`), `Blocked` (a task `Failed` or `Blocked`; `block_reason` names the open `Blocker` question), `Pending`
  (no task `Done`, `In Progress` or `In Review`: nothing has started), `Building` (open tasks, and at least one task
  started or `Done` -- so a delivery a correction reopens after it had `Done` tasks shows `Building` at once),
  `Verifying` (no open task, `verify` missing or stale), `Approving` (its approval missing or stale), `Done` (closed).
  No step writes it, and the routing never reads it; the dashboard shows it. Both writers -- the canonical one and the
  dashboard fork -- derive it the same way, held equal by the writer parity case (Testing).
- **Gone**: `review` (now `verify`), `quick_check`, `gate_tier` (now `tier`), `gate_grade` (now `verify`),
  `gate_timestamp`, `block_artifact` (a blocker is a `qa` entry); `dispatch_log` is no longer written (its per-task
  file is gone, Feature 006; the console dispatch lines stay).
- **`reviews`** (Feature 005) gets one entry per graded pass: `by: aid-execute`, `notes: 'task-004 verify; ledger
  <work>-task-004.md'`.
- **`qa` entries this skill writes** (Feature 002's shape): `Approval` (`covers` as in Flow), `Building` (the wave
  question and the executors' small decisions), `Blocker`, and the milestone's suggestion questions (`category:
  Pull request`).

**Writer** -- `writeback-state.sh` keeps Feature 002's lock, quoting, atomic rename and exit codes, and Feature 006's
re-render of the plan after every task or delivery state write (exit 11, fail-closed).
- `--task-id NNN --field F --value V`: F is `State`, `Base`, `Verify`, `Simplify`, `Reverify`, `Tests`, `Commit`,
  `Elapsed`, `Notes` or `Name`. `Verify` and `Reverify` take a grade or `--`; `Simplify` takes `changed`, `no change`,
  `undone` or `--`; anything else exits 4. `Review` exits 4.
- **The delivery `state` and `block_reason` are derived**, never written: every write recomputes them (Delivery
  states, above), freshness by `git merge-base --is-ancestor` or snapshot order as in NEXT. `--delivery-id NNN
  --lifecycle` exits 4, naming that.
- `--delivery-id NNN --field F --value V` (new): `Tier` (`Small`, `Medium`, `Large`), `Base`, `Verify`, `Simplify`,
  `Reverify`, `Tests`, `Commit`, `Issue List`; same validation.
- `--pipeline --field "Wave Stops" --value V`: `wave_stops.choice` -- `none`, `review`, `review-and-update`.
  `--pipeline --field "Planned Wave Stops" --value V`: `wave_stops.planned` -- `--`, or comma-separated
  `delivery-NNN/wave-N` items; anything else exits 4.
- `--full-suite --field F --value V` (new): `Command`, `Baseline`, `Baseline Commit`, `Result`, `Commit`.
- `--feedback-add --kind K --ref R --summary T` (new; run by `/aid-monitor-pipeline`): appends an `Open` entry and
  prints its id. `--feedback --id F<n> --state S [--link L]` (new): updates it.
- `--plan-sync` -- Feature 006's mode, extended here (as Feature 005 extended Feature 004's `--review`):
  `--cancel task-NNN[,task-NNN]` sets `Canceled` on each named task that is `Failed`, `Blocked` or `Pending` (any
  other state exits 4 and nothing is written), and every run sets `Pending` on a `Blocked` task none of whose
  dependencies is `Failed` or `Canceled`. Task files are kept: a started task is never removed (Feature 006). It
  sets no delivery state: that is derived (above).
- **Gone**: `--findings`, `--append-issue`, `--gate-field`, `--block` -- each exits 4 with a line naming its
  replacement.

##### 4. Components

**`/aid-execute` description and guide line** (Feature 001's shape; final text set at build):
- `description:` "Build a work's planned tasks one at a time -- each built, tested, verified and simplified -- and stop
  for approval only at the end of each delivery and of the whole build. Use when a plan is approved and building
  should start or continue."
- Skill-guide line, within SG-03's limit: `` - `/aid-execute` -- build and test the planned tasks; after the plan is approved ``

**Approvals** -- `skill-steps.md` § When approvals happen keeps Feature 002's rows (the confirmation, the chosen wave
ends, each delivery, the whole build, the final result) and gains:

| Moment | `full` | `lite` |
|---|---|---|
| Corrections made after the whole build is approved, before they are pushed (FR-7) | approve | approve |

and one rule under the table: "During Building, a question that does not block is not asked: the agent's
recommendation is recorded `Assumed` and confirmed at the next milestone. A question the work cannot go on without is a
real blocker, asked at once and recorded `category: Blocker`. An approval a revision needs at once is asked at once too,
recorded as that revision's `Approval` (`covers: requirements change` or `plan change`), never as a `Blocker`." The
corrections approval is the MILESTONE a correction call reaches -- the last delivery's and the whole build's again,
`covers: delivery delivery-NNN; whole build; final result` -- with no collection and no push question
(`/aid-monitor-pipeline` does both).

**Full suite** (Q79): the command comes from the KB's `test-landscape.md` or `technology-stack.md`; with neither, from
the project's own build files, recorded `Assumed` with reach `project` (so the next approval's KB call records it). A
project with no test suite records `command: none found`, and FINAL says so at the approval. The baseline and the final
run record what passed and the failing tests by name.

**`simplify-guard.sh`** -- `simplify-guard.sh --tests <list-file> (--before <commit> | --snapshot <dir>)`: with git,
`--before` compares `<commit>` with `HEAD`; without git, `--snapshot` compares the working files with the simplify
round's snapshot (Flow, BUILD, Without git). Exit 0 when no file of the list, nor any new file in the list's folders,
changed; 1 otherwise, naming each; 2 bad argument; 3 only when neither can be used (no git and no snapshot). Bash
only, like the other `execute/` scripts. Rationale: "no test is changed or removed to fit" (FR-19) must be exact, so
it is a script (decision D17).

**`derive-waves.sh --from-tasks <work-dir> --delivery NNN`** -- the dependency table and wave block of one delivery,
the same sort as `--plan` (Feature 006): a dependency on an earlier delivery's task is met. BUILD's order,
`complexity-score.sh` and the wave milestones read it; `compute-block-radius.sh` reads the unscoped output, so a
failed task blocks its dependents in later deliveries too.

**The shortcut engine** (until Feature 009): APPROVAL-HALT's yes is recorded `category: Approval`, `covers:
REQUIREMENTS.md; PLAN.md; confirmation before building`, so `/aid-execute` asks only the wave question and a doorway
work gets one approval before building (AC-10). Its "run `/aid-execute` when ready" line stays.

**Dashboard** (both readers, kept equal by the parity tests; AC-41):
- **Task cells**: state, and for the task being built a plain stage from the record ("being tested", "being reviewed",
  "being simplified"); `verify`, `simplify`, `reverify`, `tests`. The quick-check display goes.
- **Delivery cells**: the seven states, `verify`, `tests`, `issue_list`; the gate tier and timestamp go.
- **The work card**: "Waiting for your approval: end of delivery-002" at a milestone; "Needs your decision" for an open
  `Blocker` entry; the full-suite result once FINAL has run. No step names (Feature 002).
- `_ser_work` and `reader.mjs` pass `wave_stops`, `full_suite` and the new task and delivery fields; `feedback` is read
  and not shown. The stop and finish controls are unchanged.

**Kept invariant**: `/aid-execute` changes product code and tests only through its executors, the work file only
through the writer, `REQUIREMENTS.md` only through `/aid-specify`, the plan and the task files only through
`/aid-plan`, and a KB document only through `/aid-kb-update`. It never pushes, never merges, and makes no branch and
no worktree (AC-34).

##### 5. What other features must provide

| Feature | Must provide | Waiting on it |
|---|---|---|
| 008 | `/aid-monitor-pipeline` offers three entries: a read-only collect `CALL` that adds each new review comment and pipeline result with `--feedback-add` and returns; a push `CALL` that pushes the work branch only up to the newest approved `commit`, creates or updates the one pull request, records `pull_request` (the work file key it adds), and returns; and the close, as the `PASS` target with phase `CI`. Its corrections after the whole build go through `/aid-plan` REVISE (ordinary tasks in the last delivery that has a `Done` task, `Assumed`) and a correction `CALL` to `/aid-execute`, which builds them, verifies the delivery and runs the full suite again (both stale), asks the last delivery's and the whole build's approval again, and returns. It resolves a conflict with the parent branch itself (KI-005); Building never brings the parent branch in. It commits the work folder as the project setting says. Its local clean-up also deletes the work's old local delivery branches left by Migration | `007-13` |
| 009 | The shortcut engine's APPROVAL-HALT goes with the engine, and with it the recorded-confirmation edit above | -- |

**Owed to this feature by Features 001-006, and where each is met:**

| From | Owed | Met in |
|---|---|---|
| 001 | The depth table: `lite` has one approval before building, plus the final result | Flow (START, MILESTONE) |
| 001 | The close minimum by `/aid-orchestrate` until Feature 008 | Flow (FINISH) |
| 001 | The what/when `description:` and the skill-guide line | Components |
| 002 | The approvals table rows: the confirmation before building (with the wave question), the chosen wave ends, each delivery, the whole build, the final result; coinciding approvals are one; `Approval` entries with `covers` and `commit`; `user_approved` | Flow (START, MILESTONE, FINISH); Components (Approvals) |
| 002 | How a milestone runs is `/aid-execute`'s | Flow (MILESTONE) |
| 002 | `skill-steps.md` and the question protocol cited; no banners; `### What to report` in the brief | Files and layout; Testing (EX-02) |
| 002 | NM-04's `aid-execute` exemption goes | Files and layout (no "merge to main"); Migration (Suites) |
| 002 | The `skill:aid-execute` AC-28 row; samples `002-07`, `002-08`, `002-09`, `002-13` | Testing |
| 003 | The draft deletion fires on the `lite` confirmation (`003-10`) | Flow (START) |
| 003 | A side idea from Building returns to the saved step (`003-07`) | Flow (Changing the plan) |
| 004 | Per-delivery branches gone; the work branch compared against `pipeline.parent_branch`, never `master` | Flow (BUILD, DELIVERY, Migration); Components (Kept invariant) |
| 004 | The KB check after each verified, committed task; the call stamps at that commit | Flow (NEXT) |
| 004 | Backlog and roadmap items at the end of the whole build | Flow (FINAL) |
| 004 | The milestone approval lists `kb_updates` | Flow (MILESTONE) |
| 004 | No KB: no call, one line per work; a KB-update question blocks only when needed; `kb-gap` becomes the call | Flow (NEXT, BUILD, Real blockers) |
| 004 | Samples `002-13`, `004-11`, `004-12` | Testing |
| 005 | The KB call on confirmation at the confirmation and at every milestone; the `lite` confirmation approves `REQUIREMENTS.md` | Flow (START, MILESTONE) |
| 005 | `wrong-assumption` and `architecture-conflict` become a `CALL` to `/aid-specify` (REVISE) | Flow (BUILD) |
| 005 | The unsplit shape read through the slice | Flow (START, BUILD) |
| 005 | A requirement change after the `lite` confirmation is approved at once, a real blocker (Q70) | Flow (Real blockers) |
| 005 | Samples `005-11`, `005-12` | Testing |
| 006 | Tasks, dependencies and delivery from the task files; the graph scripts and wave milestones through the same sort; state from `tasks_lifecycle` and `deliveries`; `pipeline.path` and the full-path branches gone | Flow (START, NEXT); Components (`derive-waves.sh`); Files and layout |
| 006 | After a recorded `covers: PLAN.md; confirmation before building`, only the wave question; otherwise the confirmation is the approval (Q73) | Flow (START) |
| 006 | A task that finds the plan wrong, and a return from `/aid-specify` REVISE that changed what tasks serve, make a `CALL` to `/aid-plan` (REVISE) | Flow (BUILD, Changing the plan) |
| 006 | `delivery-NNN-issues.md` and `--append-issue` fold into `deliveries.<id>.issue_list` | Work state; Migration |
| 006 | The entry step is `START`; the `aid-execute` `PL-04` row on the shared exempt list goes | Flow; Migration (Lists) |
| 006 | The delivery building states | Work state |
| 006 | Sample `006-06` | Testing |

##### 6. Risks

- **Review cost.** Every task now gets a graded review (FR-19) where today it gets an ungraded quick check, plus a
  simplify pass. Contained by the reviewer tiers, a simplify pass with no grade and no loop, and a re-verify scoped to
  the simplify commit.
- **Feature 008 is not built yet** (Feature 006's precedent: no bridge, no release between them). The collect and push
  steps run only when a pull request or a remote exists; the samples that need one wait on the deferred list, and the
  close runs through `/aid-orchestrate` until Feature 008.
- **One task at a time** (Q76) takes longer on a wide plan than today's pool. The trade is honest test results and one
  commit history per work.
- **The full suite's cost**: it runs twice per work (baseline and end) and again after each fix round at the end. A slow
  suite makes FINAL slow; the one-line progress line says so (Feature 002).
- **Without git** there are no commits: the snapshots BUILD takes (Flow, BUILD, Without git) stand in for `base`, the
  diffs and the undo, at the cost of a copy of the project per round.
- **`rules.md`** (tracking discipline) says "`In Progress` at the start of EXECUTE"; the step is now BUILD. The meaning
  holds, but the line needs rewording when this feature is built (tracked with KI-001); its summary bullet is unchanged.
- **The KB says the opposite today**: `pipeline-contracts.md` (the parallel-pool contract, two-tier review, loops L6 and
  L7 through `IMPEDIMENT-task-NNN.md`), `quality-gates.md` (the delivery gate), `architecture.md`, `domain-glossary.md`
  (Max Concurrent, the execution graph). Migration updates them; the user documentation waits for the final pass
  (AC-45).
- **A doorway work's double approval** if the shortcut engine's APPROVAL-HALT edit is missed; EX-06 checks it.

##### 7. Migration

| Old | New |
|---|---|
| `/aid-execute work-NNN task-NNN`, `/aid-execute delivery-NNN` | `/aid-execute` builds the whole plan, one task at a time; to change a task, say what should change |
| `aid/<work>-delivery-NNN` branches, "merge to main" | One branch per work; the merge is yours, through its pull request |
| `execution.max_parallel_tasks` | No setting: tasks are built one at a time |

- **Release notes**: the rows join the old -> new table (AC-24), drafted in `.aid/knowledge/backlog.md` § Next Release.
  No stubs (M1).
- **Installed projects**: `aid update` removes the deleted references and `delivery-issues.md` through the install
  manifest (decisions.md § D9).
- **Format 6 -- the building part** of Feature 006's work-state step (no format 7), in bash and PowerShell, byte for
  byte, idempotent:
  - `tasks_lifecycle.*.review` -> `verify`; `quick_check` -> appended to `notes`; `gate_tier` -> `tier`, `gate_grade` ->
    `verify`; `gate_timestamp` goes; delivery `Executing` -> `Building`, `Gated` -> `Verifying`;
  - each `delivery-NNN-issues.md` -> appended to that delivery's `issue_list`, then deleted;
  - each `IMPEDIMENT-task-NNN.md` or `IMPEDIMENT-delivery-NNN.md` -> one `qa` entry, `category: Blocker`, `state:
    Pending`, `context` its description, `suggested` its recommendation, then deleted; `block_artifact` goes. The
    task's `Failed` state stays.
- **At START, for an old work** (`references/old-work.md`; it needs git and judgement, so it is not in the script):
  - **Per-delivery branches** (Q80): for each `aid/<work>-delivery-NNN`, in delivery order, when it descends from the
    work branch's head, the work branch is moved forward to it (`git switch <work branch>`, then `git reset --keep
    <delivery branch>`: no merge, no rewrite). One that does not descend is a real blocker: the agent says what
    diverged and the user decides how to combine them. The old branches are left in place; Feature 008's clean-up
    removes them.
  - **Leftover task worktrees** (`.aid/.worktrees/task-NNN/` on a delivery branch): removed with `git worktree remove`
    (never forced) when they hold no uncommitted change; one that does is a real blocker.
  - Old ledgers (`execute-task-NNN.md`, `execute-delivery-NNN.md`) go with `.aid/.temp/`'s own clean-up.
- **Re-pointing**: every kept file under `canonical/`, and `dashboard/home.html`, that names a deleted reference,
  `delivery-NNN-issues.md`, `IMPEDIMENT-task-NNN.md`, `--append-issue`, `--findings`, a per-delivery branch or the
  per-task worktrees is re-pointed or reworded. Exempt: `canonical/aid/scripts/migrate/`, which reads old shapes, and
  the shared `feedback-artifacts/IMPEDIMENT.md`, which other skills still use (Feature 009). EX-05 enforces it. The
  sites today, beyond Files and layout: `aid-deploy` `references/state-verifying.md` (its "loop back to aid-execute"
  stays true and is kept) and the comment in `bin/aid`'s state converter, which describes old works and stays.
- **Site**: `site/scripts/skills/` (roster, groups), `site/scripts/.skills-manifest.json`,
  `site/scripts/lib/flow-graph/` and their `__tests__`; pages and flows regenerated by `site/scripts/gen-skills.mjs`.
- **Lists other features own** -- each changes in the same commit as the skill:
  - **Deferred list** (`tests/conversation/deferred.tsv`): the `skill:aid-execute` row goes (covered by `007-02`);
    `002-07`, `002-08`, `002-09`, `002-13`, `003-07`, `003-10`, `004-11`, `004-12`, `005-11`, `005-12` and `006-06` run
    now; `007-13` is added, waiting for Feature 008.
  - **Shared exempt list** (`tests/canonical/skill-steps-exempt.tsv`): the `aid-execute` row (`PL-04`, owner Feature
    007) goes.
  - **Never-merges test**: NM-04's `aid-execute` exemption goes.
  - **Description exempt list** (SG-04): `aid-execute`'s row, if it has one.
  - **SS-13** finds the rewritten brief by its glob.
- **Suites**. This list was built from one search, which the reviewer can re-run: every file under `tests/` and
  `dashboard/` that names a file this feature deletes -- `grep -rlE
  'state-execute\.md|state-execute-drilldown\.md|state-review\.md|state-fix\.md|state-re-run\.md|state-delivery-gate\.md|reviewer-guide\.md|delivery-issues\.md'
  tests dashboard` -- keeping the hits on `aid-execute`'s files (the same names under `aid-discover`, `aid-update-kb`
  and `aid-summarize` are other skills' files: `test-expectations-single-source.sh`, `test-ledger-isolation.sh`,
  `test-update-kb-scope-fidelity.sh` and their baseline rows are not hits). No script is deleted. Every hit:
  - `test-pipeline-status-walkthrough.sh`:
    - A1: the `aid-execute` row points to `references/start.md`, phase `Building`. A3: its impediment fixture becomes
      a `Blocker` question;
    - M4's `aid-execute` row and its B1 check: retired -- `/aid-execute` writes no phase of its own (`/aid-plan`'s
      FINISH hand-off sets Building; the `CI` write is EX-02's `finish.md` check);
    - B2's delivery-gate checks (the non-CODE stop's `Paused-Awaiting-Input` and Pause Reason in
      `state-delivery-gate.md`): retired -- that stop is gone; a blocker's pause is asserted in B3;
    - B3 (the `Blocked`, Block Reason and Block Artifact emits of `state-execute.md`, `state-review.md` and
      `state-delivery-gate.md`): rewritten over `references/blocker.md` -- it records a `Blocker` question and sets
      `Paused-Awaiting-Input`, and no `aid-execute` file writes the `"Block Artifact"` field;
    - B4a and B4b (silent-write annotation, no `Print:` in an emit block): the three deleted files leave the emit-file
      list and `references/blocker.md` joins it;
    - B4e (the impediment-write instruction kept beside the emit in `state-execute.md`): retired -- no impediment file
      is written any more; the `Blocker` question replaces it (B3);
    - B4f (the delivery gate's STOP instruction beside its pause emit): retired -- the delivery gate is gone; DELIVERY's
      three-round question is checked by EX-02 and EX-04.
  - `test-ticket-retirement-structural.sh`: re-pointed -- its `STATE_EXECUTE` path (the T000 setup list) becomes
    `references/build.md`; T037-T039 (no connector-mirror signature) hold there; T040 asserts `build.md`'s
    `In Progress` task-state write in place of the `## MANDATORY: State-Write Protocol` heading.
  - `test-compute-block-radius.sh`: T17 (the pool's degradation notice in `state-execute.md`) retired -- the pool and
    its notice are gone (Q76); the rest follows the new graph input (Testing).
  - `test-delivery-gate-aggregate.sh`: retired -- the delivery gate, its issue log and the quick check are gone.
  - `test-task-state-transitions.sh`: re-pointed -- its header and the mandate it cites name `references/build.md`.
  - `test-scoped-review-cycles.sh`: re-pointed -- the comment above SW01-SW04 names `aid-execute/references/fix.md`,
    where the FIX contract's F1 now lives.
  - `tests/cost-meter.py`: kept -- its `today` shape models the old quick check on purpose, as the baseline the
    alternatives are measured against.
  - `dashboard/reader/derivation.py`: re-pointed -- the comments naming the old producers of `Blocked` and
    `IMPEDIMENT-task-NNN.md` name `references/blocker.md`; its reads stay for old works.
  - `dashboard/reader/tests/test_integration.py`: re-pointed -- the docstring's "last Running emit" names the running
    skill's step entry instead of `state-execute.md`.
  - `dashboard/scripts/writeback-state.sh`: its comments citing `state-review.md` and `state-delivery-gate.md` go with
    the `--findings` and `--block` modes (Files and layout).
  - `tests/cost-baseline.tsv`: the `delivery-issues.md` template row goes.
  - `tests/coverage-baseline.tsv` and `tests/coverage-rehome-allowlist.tsv`: the rows of the assertions above are
    re-recorded; the removed ones go to `tests/coverage-accepted-removals.tsv`.

  Beyond that search:
  - Retired, to `tests/coverage-accepted-removals.tsv`: `test-disjoint-merge.sh` -- its subject, delivery branches
    merging back, no longer exists (Feature 006 lists it among the suites that follow the single layout).
  - `test-executor-graph-flat-plan.sh`: rewritten so `complexity-score.sh` and `compute-block-radius.sh` read
    `derive-waves.sh --from-tasks` output, scoped and unscoped.
  - `test-writeback-state.sh`: the `--findings`, `--append-issue` and gate units retire; the new fields, states and
    modes are added (Testing).
  - `test-downstream-worktree-entry.sh`: its `aid-execute` assertions go (the skill no longer enters a worktree itself).
  - `test-complexity-score.sh`, `test-derive-waves.sh` (`--delivery`), `test-work-state-template.sh`,
    `test-lite-work-end-to-end.sh` and the dashboard reader, server and parity suites follow; old fixtures stay where
    they now check the migration.
- **User documentation** waits for the final pass (Q40, AC-45). The only edit now: the numbers `test-doc-counts.sh`
  asserts.
- **KB** (no work ids):
  - `pipeline-contracts.md` (the Building contract and state machine; the parallel-pool contract and two-tier review
    go; loops L6 and L7 become the calls to `/aid-specify`, `/aid-plan` and `/aid-kb-update`, and blockers);
  - `quality-gates.md` (task and delivery verification, simplify and re-verify replace the quick check and the delivery
    gate; the three-round rule);
  - `architecture.md` (the Execute rows; one worktree and one branch per work);
  - `artifact-schemas.md` (the building part; `delivery-NNN-issues.md`, `IMPEDIMENT-task-NNN.md` and
    `execution.max_parallel_tasks` go);
  - `domain-glossary.md` (milestone, real blocker, simplify, re-verify, full-suite baseline; Max Concurrent, quick check
    and delivery gate go), `coding-standards.md` (its settings-key example), `capability-inventory.md`,
    `module-map.md`, `test-landscape.md` (the new suites), `tech-debt.md`;
  - `decisions.md` gains "one task at a time in the work's one worktree; every task and delivery goes build, test,
    verify, simplify once, and re-verify only when the simplification changed something", which supersedes the
    parallel pool and the two-tier review; D6 stays.
  - Then `INDEX.md` is regenerated and `kb.html` rendered by the script (Feature 004).

##### 8. Testing

Per NFR-T (Q35): unit tests and static checks now; a sample that needs a later feature waits on the deferred-tests list;
the full integration suite runs at the end of the work, before release, with that list empty.

**Static checks -- `tests/canonical/test-execute.sh`** (picked up by `tests/run-all.sh`; added to the suite list of
`.github/workflows/installer-tests.yml`):

| Group | Asserts |
|---|---|
| EX-01 | `aid-execute`'s new references and brief exist, its deleted references do not; `delivery-issues.md` is absent; `simplify-guard.sh` exists |
| EX-02 | The step table has START, BUILD, TEST, VERIFY, SIMPLIFY, REVERIFY, NEXT, DELIVERY, FINAL, MILESTONE and FINISH; FINISH advances by `PASS` and `finish.md` names `--phase CI`; `start.md` names `confirmation before building`, `Wave Stops` and the baseline; `milestone.md` names `aid-monitor-pipeline`, `aid-plan`, `covers` and `commit`; `next.md` names `kb-freshness-check.sh` and `aid-kb-update`; `blocker.md` names `Blocker`, `Assumed`, the give-up choices and `aid-plan`; `SKILL.md` cites `skill-steps.md` and `question-protocol.md` |
| EX-03 | One worktree and one branch (AC-34): no file under `canonical/skills/aid-execute/` or `canonical/aid/scripts/execute/` creates a branch or a worktree (`git worktree add`, `git checkout -b`, `git switch -c`, `git branch <name>`) or names `run_in_background`, `max_parallel_tasks` or "merge to main"; a `-delivery-` branch is named only in `references/old-work.md` |
| EX-04 | `simplify.md` names `simplify-guard.sh`, once per task, and `undone`; `verify.md` names `grade.sh`, `--review`, `git reset --keep` and the three choices after three rounds with `Accepted` |
| EX-05 | No tracked file under `canonical/skills/`, `canonical/aid/templates/` or `canonical/aid/scripts/` (except `migrate/`, and the writer's refusal of its retired modes) names `IMPEDIMENT-task-`, `delivery-NNN-issues`, `--append-issue`, `--findings` or `quick_check` |
| EX-06 | `skill-steps.md` § When approvals happen has the corrections row and the Building rule; `shortcut-engine.md` § State: APPROVAL-HALT names `confirmation before building`; `reviewer-ledger-schema.md` names the four `/aid-execute` ledgers |
| EX-07 | `work-state-template.yml` has `wave_stops`, `full_suite`, `feedback`, and the building fields of `deliveries` and `tasks_lifecycle`, each with its `[W]` comment, and no `gate_tier`, `gate_grade`, `gate_timestamp`, `quick_check` or `review:` under a task |
| EX-08 | The routing reads states plus commits: `next.md` names `verify`, `full_suite`, `commit`, `covers` and `merge-base --is-ancestor`, and each `covers` form -- `wave delivery-`, `delivery delivery-`, `whole build` -- which `milestone.md` also writes; its wave rule names a later wave with an open task and fires only while the current delivery has no `verify` recorded and no `full_suite` result has been recorded, and only for a wave end on `wave_stops.planned` with no answered (yes or change) `wave delivery-` entry -- a wave stop is asked once, and only where planned; only `start.md` writes `Planned Wave Stops`, once, with the choice. No file under `canonical/skills/aid-execute/` reads or writes a stored delivery state (`--lifecycle`, `deliveries.<id>.state`), or names `corrections <` or a correction task's milestone in `notes` |

**Unit tests**
- `tests/canonical/test-writeback-state.sh`: each new task and delivery field, with its values and exit 4 on a bad
  one; `--lifecycle` and the old delivery states refused; `"Wave Stops"` and `"Planned Wave Stops"`, with a malformed
  list refused; `--full-suite`; `--feedback-add` ids and
  `--feedback` updates; `--plan-sync --cancel` on `Failed`, `Blocked` and `Pending` tasks, exit 4 on a `Done` one, and
  a rewired `Blocked` task back to `Pending`; the derived delivery state for each of its seven cases, recomputed after
  a task write, a `--plan-sync --cancel` and an approval -- a correction added to a `Done` delivery shows it
  `Building` at once; one added to an all-`Canceled` delivery that never started shows it `Pending` until its task is
  `In Progress`, then `Building`; a new task commit after its `verify` shows it `Verifying`; the writer parity case:
  the canonical writer and the dashboard fork, run on the same fixtures, write the same derived states; `--findings`,
  `--append-issue`, `--gate-field` and `--block` exit 4 naming their replacement; a task write still re-renders the
  plan; every file written parses through the dashboard reader with no warning.
- `tests/canonical/test-simplify-guard.sh`, on throwaway repositories and on throwaway folders with no git: an
  untouched test list exits 0; a changed, a removed and an added test file each exit 1 naming it, with `--before` and
  with `--snapshot`; no git and no snapshot exits 3.
- `tests/canonical/test-derive-waves.sh`: `--from-tasks --delivery` prints one delivery's table and waves, a dependency
  on an earlier delivery counted as met; the unscoped output is unchanged.
- `test-complexity-score.sh` and `test-compute-block-radius.sh` on `derive-waves.sh --from-tasks` output; without
  `--delivery-id`, a failed task blocks a dependent in a later delivery; with it, the scoped result is today's.
- `tests/canonical/test-work-state-migration.sh` (Feature 006's) gains: the renamed fields and states, an issues file
  and an impediment file folded and deleted, a second run changing nothing, bash and PowerShell giving the same bytes.
- Dashboard: fixtures for a work in Building with a task being verified, a delivery at its milestone, an open
  `Blocker` entry and a finished full suite; `test_index_html.py` for the card lines; the parity tests.

**Conversation samples -- `tests/conversation/samples/feature-007/`** (frontmatter `skills: aid-execute`; each fixture
a small project with code and a test suite, no remote unless named)

| Sample | Covers | Runs |
|---|---|---|
| `007-01-lite-one-approval-to-result` -- a `lite` bug fix with its requirements and plan written. Check: one approval before any code change, `covers: REQUIREMENTS.md; PLAN.md; confirmation before building`; no wave question; no other question until the final approval; each task `Done` with `tests` passed, `verify` at or above the bar and a `simplify` value; the final approval shows the task tests and the full suite against the baseline; `user_approved: 'yes'`; a pass to the close | AC-26, AC-32, AC-10 | now |
| `007-02-full-after-plan-approval` -- a `full` work whose plan approval covers the confirmation; a delivery with two waves. Check: no second approval; one wave question, recorded `category: Building`, following the protocol | AC-32, AC-28 | now |
| `007-03-review-per-wave` -- as `007-02`; the user picks a review per wave. Check: an approval at the end of wave 1 (run also with a change asked there: the wave-1 stop is not asked again, and the correction is approved at the delivery milestone; and with three chained corrections asked there -- C2 depending on C1, C3 on C2 -- so that C3 opens a third wave the two-wave fixture never had: `wave_stops.planned` is unchanged and no wave stop is asked at the new wave end); the delivery end, the whole build and the final result as one approval; no pull-request question. Second run: a work with two deliveries, delivery-002 all `Canceled`; at the combined `delivery delivery-001; whole build` milestone the user asks for a change. Check: the answer is recorded as a change, not a yes; the correction joins delivery-001 and is built; DELIVERY runs again, then FINAL; one combined milestone is asked again, with no wave stop and no milestone asked with nothing new built | AC-32 | now |
| `007-04-failing-test-not-done` -- the task's first build leaves a planted test failing. Check: the task is not `Done` until its tests pass; a fix round happened; `tests` names the passing run | AC-26 | now |
| `007-05-simplify-no-change` -- a task with nothing to simplify. Check: `simplify: no change`, `reverify: --`, and no re-verify entry in `reviews` | AC-33 | now |
| `007-06-simplify-then-reverify` -- a task that copies a helper the code already has. Check: `simplify: changed`; a re-verify entry in `reviews` and a `reverify` grade; the simplify commit touches no test file; `tests` the same before and after | AC-33 | now |
| `007-07-two-deliveries` -- a work with two deliveries. Check: a delivery verify, one simplify and, when it changed, a re-verify recorded for each delivery before its approval; an approval after delivery-001; the full suite before the last approval, which is one approval | AC-32, AC-33 | now |
| `007-08-kb-conflict-blocker` -- a task that needs a choice the KB rules out. Check: one `Blocker` question with a recommendation, the work paused, no other task built before the answer, then the build goes on from the same step | AC-32 | now |
| `007-09-one-worktree-one-branch` -- a complete ticket for a two-delivery change, from the first message through Specification, Planning and Building to the final approval. Check: `git worktree list` shows one worktree added for the work and `git branch` one branch; no `-delivery-` branch; no merge commit | AC-34 | now |
| `007-10-baseline-failure-reported` -- a test already failing on the parent branch. Check: `full_suite.baseline` names it; at the end it is reported at the approval, no task is made for it, and the work's own failures are fixed | AC-26 | now |
| `007-11-change-at-milestone` -- at the delivery-001 approval the user asks for a change. Check: a `handoffs` call to `aid-plan`, a new task with a `Plan change` entry `Assumed`, built through the loop, then the same milestone asked again | AC-32, AC-33 | now |
| `007-12-old-delivery-branch` -- an old work after `aid update`, built on a delivery branch that descends from the work branch, with a second one that diverges. Check: the work branch moved forward to the first with no merge commit; one `Blocker` question for the second | AC-34, AC-37 | now |
| `007-13-milestone-collect-and-push` -- fixture: a remote and an open pull request with a bug comment. Check: a collect call returned, a correction task built, an approval with its `commit`, the push question; after yes, the pushed head equals that `commit` | AC-32, AC-42 | deferred: Feature 008 |

The undo of a failed re-verify (Q78) is checked by EX-04 and `test-simplify-guard.sh`: a planted failing re-verify is
not reproducible in a scripted conversation. Feature 001's `001-07-rich-ticket` and `001-16-work-closes-done`, and
Feature 006's `006-01`, run again at this feature's end.

##### Criteria traceability

| Criterion | Where satisfied | How verified |
|---|---|---|
| AC-26 | Flow (TEST, NEXT: `Done` only after the tests pass; FINAL and MILESTONE: the final result shows the task tests and the full suite against the baseline); Components (Full suite) | EX-02; writer unit tests; `007-01`, `007-04`, `007-10` |
| AC-32 | Flow (START: the confirmation and the wave question; MILESTONE; Real blockers); Components (Approvals) | EX-02, EX-06; `007-01`, `007-02`, `007-03`, `007-07`, `007-08`, `007-11`; `007-13` (deferred) |
| AC-33 | Flow (VERIFY, SIMPLIFY, REVERIFY, DELIVERY); Work state (`verify`, `simplify`, `reverify`, `tests`, `reviews`); Components (`simplify-guard.sh`) | EX-04; `test-simplify-guard.sh`; `007-05`, `007-06`, `007-07`, `007-11` |
| AC-34 | Flow (one worktree, one branch, one task at a time); Components (Kept invariant); Migration (old delivery branches and task worktrees) | EX-03; `007-09`, `007-12` |

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
