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
  skill per action, with the kind as an argument; the rules for each kind live in one catalog (Feature 009).
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

| Depth | Mandatory approvals |
|---|---|
| `full` | **Every document** is confirmed by the user (seed, requirements, task plan, ...), plus the final result. |
| `lite` | **One approval before Building starts** -- the agent always confirms what it is about to build (for a small fix, one short line) -- plus the final result. |

- **There is no depth without a confirmation before building.** Even the smallest work is confirmed before Building starts.
- **Always an approval at the end**, on the final result, at every depth -- **before the PR/MR is created or updated**.
- **Building milestones.** After the confirmation before building (which is not a milestone), building runs
  without the user, and stops for approval only at:
  - **Required:** the end of **each delivery**, after verification, before creating or updating a PR/MR;
    and the end of **the whole build**, after verification, before creating or updating a PR/MR.
  - The approval at each required milestone also asks **"Create or update the PR/MR now?"**; the user's
    yes is the instruction FR-7 requires. Building then hands the work to the CI skill
    (`/aid-monitor-pipeline`, FR-20 hand-off), which creates or updates the PR/MR and starts watching it
    while building continues with the next delivery. The CI skill is the only one that touches the PR/MR.
  - **Optional** (the agent asks during the confirmation before building whether the user wants it): the end of
    **each wave**, after verification -- a review per wave, and/or a PR/MR update per wave.
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
- **CI is the pull-request phase.** Once the PR/MR exists, CI manages it to a mergeable
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

## 6. Non-Functional Requirements

- **NFR-N (naming).** No acronyms in artifact or skill names: names say plainly what the thing is.
  The Specification phase produces `REQUIREMENTS.md` (not a "PRD" file). Accepted exception: **KB**,
  an established term in AID (`/aid-kb-build`, `/aid-kb-query`, `/aid-kb-update`, `/aid-kb-show`).

- **NFR-T (testing behaviour).** Criteria about how the agent behaves are checked by a **conversation
  test suite**: each has a few scripted sample conversations with an expected outcome; each runs
  **3 times** and passes only if all 3 runs meet it; an independent reviewer agent judges the
  transcripts. "Every skill in all five tools" is checked statically, against each tool's installed
  files. Feature 001 builds the suite; every feature adds its own samples.

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
| AC-8 | Every question to the user carries **one recommendation** and an **importance label**; several options only for real forks, never a bad option, and a free-form answer is always possible. | NFR-Q |
| AC-9 | Reviews come **one topic at a time**, in logical chunks, most important first; trivial decisions are taken by the AI and confirmed **in one batch at the end**. | Objective (digestible review) |
| AC-10 | `full`: the user confirms every document. `lite`: exactly one approval before building. Every depth: a final approval of the result **before the PR/MR is created or updated**. | FR-6 |
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
| AC-27 | CI: for an open PR/MR, `/aid-monitor-pipeline` corrects reported bugs, required corrections and pipeline failures on its own, and brings each suggestion or plain comment to the user as options with a recommendation; **every correction goes through the build process and the user's approval before it is pushed**; this continues **until a human merges the PR/MR** into its parent branch; the agent **never merges**. | FR-7 |
| AC-28 | For each skill that asks the user questions, a scripted test conversation shows: one topic per question, each with its reason, a recommendation, only valid options and a free-text answer; groups of 3-5 by subject, most important first; a break offered after each group and at each change of subject; follow-ups right after the question that raised them; answered or trivial questions skipped; a skipped question recorded as open and resumable later by the same or another user. | FR-17 |
| AC-29 | A ticket pulled in mid-work is **recorded as a work source** in `STATE.yml`; the pending questions it answers are closed, any new questions are added, and the phase advances when its conditions are met; on request, the agent **writes the work's information back** to the source; project sources are used by every work when needed without being attached. | FR-18 |
| AC-30 | For every kind in the catalog, the typed form (`/aid-<action> <kind> ...`) and a plain-words request for the same thing reach **the same skill and the same rules**. | FR-4, FR-8 |
| AC-31 | No skill name combines an action (create, update, design, document, test, prototype) with a kind of thing (e.g. no `/aid-create-api`); the dashboard and chat show **only current skill names**. | Scope, M1 |
| AC-32 | During building, the user is asked for approval **only** at the end of each delivery and at the end of the whole build (each after verification, before a PR/MR is created or updated), plus at the end of each wave **only when the user opted in** during the confirmation before building; real blockers (something the agent cannot decide or fix on its own, including a conflict with the KB) are the only other interruptions. | FR-6 |
| AC-33 | For each task and each delivery, the work record shows verify -> simplify, and a scoped re-verify **only when** the simplification changed something; simplification runs once, and the test set before and after it is identical and passing. | FR-19 |
| AC-34 | Running a work from start to PR/MR creates **exactly one worktree and one branch** for it; no skill or script creates a per-delivery branch or merges anything. | FR-6 |
| AC-35 | The PR/MR diff contains **only changes meant for the parent branch**: no file under `.aid/.temp/`, files under `.aid/works/` only when the project setting is **push**, and no commit that adds and later removes files. | FR-7 |
| AC-36 | After a human merges the PR/MR, the work is marked **done** and clean-up is local only (temporary files, local branch, worktree); **no remote branch is deleted** by AID. The work folder is pushed, kept locally, or deleted exactly as the project setting says. A work in a project with no repository is still marked done at the end. | FR-7 |
| AC-37 | During a work, no state banner or "you are here" map is shown unless the user asks; after an interrupted session, a new session resumes at the step saved in `STATE.yml`; every stop that needs the user follows FR-17. | FR-20 |
| AC-38 | In a scripted work, (a) at the end of Definition the work passes to Specification **without the user typing a command**, and (b) when Building needs a KB update mid-task, the KB update runs and the work **returns to the same step**; `STATE.yml` records each hand-off (from, to, why, return point). | FR-20 |
| AC-39 | Roadmap and backlog are ordinary KB documents and the MVP is a section of the roadmap, all created and updated through the normal flow with **no dedicated skills**. | FR-14 |
| AC-40 | The question protocol is run by the main conversation; the interviewer sub-agent no longer exists. | FR-13, FR-17 |
| AC-41 | The dashboard and chat read the work's state from the new `STATE.yml` layout (FR-20) and show it correctly for a work at each phase. | FR-20, Scope |
| AC-42 | At each required building milestone the approval asks whether to create or update the PR/MR; on yes, the work is handed to `/aid-monitor-pipeline`, which alone creates or updates it, while building continues; on no, no PR/MR is touched. | FR-6, FR-7, FR-20 |
| AC-43 | No `/aid-design` skill exists; a request to design a kind of thing (e.g. "design the orders API") reaches `/aid-brainstorm` with that kind's catalog rules, and only `/aid-brainstorm` writes idea drafts under `.aid/design/`. | Scope, FR-9 |

### Skills, naming and constraints

| # | Check | Covers |
|---|---|---|
| AC-20 | Each skill has **one clear job** and no two skills overlap; skills that hold no logic of their own (pure wrappers) are gone, their variations kept as data. **No fixed skill count**: the final number is set by evaluating whether the agents solve developers' problems efficiently. | Scope, Problem 3 |
| AC-21 | **Every** AID skill can be run by slash command in all five tools, and the agent can also run it on its own. | FR-8 |
| AC-22 | Phase skills are named `/aid-kb-build`, `/aid-brainstorm`, `/aid-specify`, `/aid-plan`, `/aid-execute`, `/aid-monitor-pipeline`; **no skill or artifact name uses an acronym**. | FR-11, NFR-N |
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

## 11. Features

Every feature is **Must**; the order below is the build order (§10). Every feature must also pass
AC-22, AC-24 and AC-25.

### Feature 001 — Ask for Work in Plain Language

- **Priority:** Must
- **Requirements:** §5 FR-1, FR-4, FR-5, FR-7, FR-8, FR-13, FR-18; §6 NFR-T
- **Criteria:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-14, AC-21, AC-23, AC-29

#### Description

The agent in the user's own tool reads a plain request by its meaning, checks it against the skill guide in `rules.md`, the KB and the code, and proposes the matching workflow -- or just continues when nothing matches. It sizes the work (`full` / `lite`) and runs only the phases the work needs around the Specify -> Plan -> Execute core. Project questions are answered from the KB with sources. Information from external sources -- project sources in the KB, or work sources attached to one work -- is applied to the work at any moment, and written back to the source on request. `/aid-triage` folds into the skill guide. The orchestrator sub-agent retires; every skill stays runnable by slash command.

#### User Stories

- As an AID user, I want to say what I need in my own words and have the agent pick the right process, so that I never need to know skill names.
- As an AID user with a complete ticket, I want to go straight to requirements and plan with one approval, so that small, well-defined work is not slowed down.
- As an AID user, I want a question about my project answered from the KB, with sources, without starting a work, so that a quick question stays quick.

#### Technical Specification

*(pending -- added by `/aid-specify`)*

### Feature 002 — Clear, Step-by-Step Decisions

- **Priority:** Must
- **Requirements:** §5 FR-6, FR-7, FR-17, FR-20; §6 NFR-Q
- **Criteria:** AC-8, AC-9, AC-10, AC-11, AC-28, AC-37, AC-38, AC-40, AC-41

#### Description

Improves how AID talks with the user and how skills move through their states. Questions come one topic at a time, each with a recommendation and an importance label; reviews arrive in chunks, most important first; minor decisions are confirmed in one batch at the end. Approvals follow the depth, with a final approval before any PR/MR, and nothing ever merges. Includes the question protocol (FR-17), which replaces the separate interview step and is used by every skill that talks with the user, and a revision of the skill state machines (FR-20): steps invisible to the user, the current step always saved, one shared set of rules, and automatic hand-offs to another skill -- at the end of a process or in the middle of it, returning to the same step. Every phase skill built after this feature follows these rules.

#### User Stories

- As an AID user who tires of long documents, I want decisions one topic at a time, most important first, each with a recommendation, so that I can decide well without being overwhelmed.
- As the decision-maker, I want a final approval before any PR/MR and a guarantee that nothing merges on its own, so that I keep control of what ships.

#### Technical Specification

*(pending -- added by `/aid-specify`)*

### Feature 003 — Shape an Idea or Ticket into a Clear Work Definition

- **Priority:** Must
- **Requirements:** §5 FR-1, FR-9, FR-11
- **Criteria:** AC-17, AC-43

#### Description

`/aid-brainstorm` shapes an idea with the user, across sessions if needed -- also for a specific kind of thing (an API, a UI, a data model, ...), using the catalog's rules for that kind, which replaces today's `/aid-design-*` skills; a ticket or other external source can feed it, as it can any phase (FR-18). The shaped idea lives in `.aid/design/` and is deleted once its requirements are approved. Absorbs today's describe step.

#### User Stories

- As an AID user, I want to shape an idea across sessions, or hand over a ticket, and have it turned into a clear starting point, so that work begins from a well-understood problem.

#### Technical Specification

*(pending -- added by `/aid-specify`)*

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
- **Criteria:** AC-12, AC-16

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

`/aid-plan` (today's plan and detail merged) writes `PLAN.md` as an improved TODO list: deliveries with their acceptance criteria, waves, atomic tasks, dependencies and state. Each task keeps one instruction file, linked from `PLAN.md`, with no state of its own. One `STATE.yml` per work; no delivery documents or state files. Tasks are grouped into deliveries and waves that respect the task dependency tree.

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

`/aid-execute` carries out the plan's tasks and tests them: a task is done only when its tests pass, and the result shows the test outcome. The user is involved only at the milestones (end of each delivery and of the whole build; optionally each wave); each task, and each delivery as a whole, goes through verification, then a lighter simplification pass, then a scoped re-verification only when the simplification changed something (FR-19). Each work builds on its one worktree and branch; the per-delivery branches are removed.

#### User Stories

- As an AID user, I want every task built and tested before it counts as done, so that what I approve at the end actually works.

#### Technical Specification

*(pending -- added by `/aid-specify`)*

### Feature 008 — Pull Requests Kept on Track Through Reviews and Pipeline Failures

- **Priority:** Must
- **Requirements:** §5 FR-7, FR-11, FR-16
- **Criteria:** AC-13, AC-27, AC-35, AC-36, AC-42

#### Description

`/aid-monitor-pipeline` creates or updates the PR/MR only on the user's instruction -- given at a building milestone, which hands the work to it -- and takes it to a mergeable state: review comments, a green pipeline, hardening, security and quality reviews -- without ever merging. Reported bugs, required corrections and pipeline failures are corrected automatically; suggestions are brought to the user with a recommendation; every correction is built, verified and approved by the user before it is pushed. When GitHub or GitLab cannot be reached, the agent first helps the user connect. The PR/MR holds only the real changes; whether the work folder is pushed, kept locally or deleted is a project setting. After the merge the agent marks the work done and cleans up locally only (temporary files, local branch, worktree); it never deletes a remote branch. Marking the work done is the minimum of this phase, even for a project with no repository. It integrates with and monitors the project's CI/CD process, reacting to reviews and to pipeline failures until a human merges the PR/MR into its parent branch (usually `main` or `master`) -- the end of the work's CI. Deploying and monitoring production are separate works.

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
fold into KB management (Feature 004); `/aid-triage` folds into the skill guide (Feature 001). The
dashboard and chat show the new names.

#### User Stories

- As an AID user, I want one clear skill for each action, so that I never have to choose between near-identical names.
- As an AID user, I want to type `/aid-create api ...` or just say "create an API endpoint", so that both routes give the same result.
- As a maintainer, I want the rules for each kind of thing in one catalog, so that a change happens in one place.

#### Technical Specification

*(pending -- added by `/aid-specify`)*
