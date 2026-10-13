# Requirements

- **Name:** *(pending)*
- **Description:** *(pending)*

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

## 4. Scope

### In Scope

**Base direction** (accepted by the maintainer, from `analysis/skills-restructure-proposal.md` as
corrected by FR-5):

- The host agent is the orchestrator, guided by `rules.md` (short orchestration section + skill
  guide) and an on-demand playbook skill (FR-5).
- The skill set shrinks from 112 to about 20: six phase skills (Preparation/KB build, Ideation,
  Specification, Planning, Building, CI), setup skills (config, connectors, chat), and internal
  helpers (KB query/update/view, research, prototype, review, test, ticket, release, monitor).
- The 68 skills that hold no logic of their own (34 generated doorways, 13 kind-siblings, 21
  `aid-design-*` copies) become data: an intent catalog crossed with artifact profiles.
- Depth: every work runs the same six phases; `full` / `fast` / `direct` changes only how much the
  user reviews; intent is read by meaning and validated against the KB (FR-4); depth escalates or
  de-escalates as the work evolves.
- Agents shrink from 9 to about 7; the orchestrator and interviewer sub-agents retire (only the
  main conversation can talk with the user).
- One work layout: a single `STATE.yml` per work; no delivery- or task-level state files; waves are
  derived from task dependencies.
- The proposal's F3 (does the front door engage on every plain-language request?) is settled by
  FR-5: `rules.md` guides the host agent on every request.

### Out of Scope

## 5. Functional Requirements

### FR-1 Phase model

AID adopts the community's six phases as its phase model, replacing today's seven. Users rarely
see phase names; the phases are the backbone the orchestrator tracks.

| Phase | Produces | Absorbs today's | Notes |
|---|---|---|---|
| Preparation | the KB | Discover | |
| Ideation | a seed | Describe, Brainstorm | Describe and Brainstorm overlap. |
| Specification | `REQUIREMENTS.md` | Define, Specify | The "feature" concept must be revisited: the current skill almost always proposes more features than are actually necessary, and its notion of a feature is not what a feature represents in a business model. |
| Planning | the tasks | Plan, Detail | Deliveries and waves are only groupings of tasks; the atomic tasks and their dependencies are the most important information. |
| Building | the outcome | Execute | Building is executing **and testing**. |
| CI | a merge-ready PR | (new) | The pull-request phase -- see FR-7. Not deploy/monitor: those are works of their own. |

### FR-2 Knowledge Base management

The KB is managed through four operations, **always handled by the orchestrator**: it identifies
when the KB should be updated, and when a piece of information about the project should be queried
from the KB. The user does not trigger them.

| Operation | Purpose | Absorbs today's |
|---|---|---|
| Build KB | Create the KB (Preparation phase) | `/aid-discover` |
| Query KB | Answer project questions from the KB | `/aid-ask` |
| Update KB | Keep the KB current as the project changes | `/aid-update-kb` |
| Visualize KB | Expose the HTML view produced during Build and refreshed during Update | `/aid-summarize` |

Summarize is no longer a separate skill: it is absorbed by Build KB and Update KB.

### FR-3 What a feature is

"Feature" keeps only its business meaning: a capability a user or customer can see and would value
on its own. The requirements document is built from **requirements with acceptance criteria**. A work is split into
several features only when it truly delivers several such capabilities; most works have one, or none
(a bug fix, a refactor). Tasks trace to requirements and acceptance criteria, not to feature folders.

### FR-4 Intent interpretation

The orchestrator does not map phrasings; it interprets **meaning**, the way a colleague would.

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
| `fast` | **One approval before Building starts**, plus the final result. |
| `direct` | The final result. |

- **Always an approval at the end**, on the final result, at every depth.
- **AID never merges anything.** The furthest it goes is pushing to the work's own branch; the merge
  is always a human act.

### FR-7 The CI phase, and operational works

- **Opening the PR is part of CI, and happens only when the user instructs it.** The agent opens a
  pull request (GitHub) or merge request (GitLab) for the work only on the user's instruction; it
  never opens one on its own.
- **CI is the pull-request phase.** Once the PR/MR exists, CI manages it to a mergeable
  state: it handles code reviews from other agents or developers, makes sure the CI pipeline
  completes green, and runs the hardening, security and quality reviews. It never merges (FR-6).
- **Operational activities are works of their own, not phases:** preparing a release, publishing,
  deploying, and starting monitoring are each an individual work, started like any other request
  ("prepare release 4.0", "deploy to staging"). They act on merged history, not on a single work.

### FR-8 How skills are invoked

- **Every AID skill stays invocable by slash command** -- that is part of the host tool's behavior,
  and AID does not change it. There is no hidden/internal split: all skills are always available.
- **The agent also starts and follows skills on its own**, behind the scenes -- equally a native
  capability of the host tools. This is how the orchestration of FR-5 works in practice.

### FR-9 Where the Ideation seed lives

The seed (the shaped idea: framing, candidate directions, open questions) lives in
`.aid/design/<name>.md` while the idea is being shaped, and is **deleted once its requirements is approved**;
its content then lives on in the requirements. An idea can survive across sessions before it is ready, and
may never become a work; work folders are disposable by rule, so the seed does not live there.

### FR-10 The KB in a greenfield project

In a greenfield project the user does not start with "build me a KB"; they start with an idea or a
task. The orchestrator **builds the KB organically from that**, and **keeps updating it along the
construction of the initial features**: each fact (stack, conventions, architecture, decisions)
enters the KB when it is actually decided or built, not guessed up front.

## 6. Non-Functional Requirements

- **NFR-N (naming).** No acronyms in artifact or skill names: names say plainly what the thing is.
  The Specification phase produces `REQUIREMENTS.md` (not a "PRD" file).

- **NFR-Q (how questions are asked).** Every question put to the user carries a
  **recommendation**. More than one option is offered only when the options are equally valid or
  mark a clear fork in the path; a bad option is never presented. The user can always give an
  alternative answer that is not in the list.

## 7. Constraints

## 8. Assumptions & Dependencies

## 9. Acceptance Criteria

## 10. Priority

## Minor decisions taken by the AI (to confirm in one batch at the end)

- **M1 -- Old slash names.** Skills that are retired take their slash names with them (clean break in
  the next major version); the release notes carry an old -> new table.
