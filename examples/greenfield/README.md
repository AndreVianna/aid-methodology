# Greenfield Example: Task Tracker API

**Scenario:** A small team needs a REST API for managing tasks — create, update,
complete, and list tasks with basic authentication. The codebase does not exist yet.
This is a greenfield project.

**AID path:** Full path (`aid-config` → `aid-describe` → TRIAGE routes to FULL → `aid-define` →
`aid-specify` → `aid-plan` → `aid-detail` → `aid-execute`)

**Why this example:** Greenfield projects skip Discovery entirely (there is no
existing codebase to analyze). The pipeline starts at Interview, and TRIAGE decides
based on scope whether to take the full path or lite path. A multi-feature API with
authentication and data persistence is large enough to warrant the full path.

---

## Table of Contents

1. [The Problem](#1-the-problem)
2. [Step 1 — Initialize AID](#2-step-1--initialize-aid)
3. [Step 2 — Run the Interview](#3-step-2--run-the-interview)
4. [Step 3 — TRIAGE Decision](#4-step-3--triage-decision)
5. [Step 4 — Specify Each Feature](#5-step-4--specify-each-feature)
6. [Step 5 — Plan the Deliveries](#6-step-5--plan-the-deliveries)
7. [Step 6 — Detail the Tasks](#7-step-6--detail-the-tasks)
8. [Step 7 — Execute](#8-step-7--execute)
9. [What You Get](#9-what-you-get)
10. [Key Takeaways](#10-key-takeaways)

---

## 1. The Problem

The team wants to ship a `tasktracker` REST API with the following scope:

- Users can sign up and log in (JWT-based authentication)
- Authenticated users can create, update, complete, and delete their tasks
- Tasks have a title, optional description, due date, and status (open/in-progress/done)
- A list endpoint supports filtering by status and sorting by due date
- Postgres as the backing store; migrations managed via a migration tool

**Stack chosen:** Node.js 22, Express 5, Postgres 16, Vitest for tests.

The team has agreed on this scope but has not written a single line of code. No existing
codebase exists.

---

## 2. Step 1 — Initialize AID

**Skill:** `aid-config`
**Why:** Before AID can do anything, it needs its configuration scaffold in the project
root. `aid-config` creates the `.aid/` directory, seeds placeholder KB documents
(14 standard templates plus meta-documents), writes `CLAUDE.md` (or `AGENTS.md`
depending on which tools you selected at install), and initializes the per-area
`STATE.md` files.

**What you do:** Create an empty git repository for the project, install AID (via
`install.sh` or `install.ps1`), then run:

```
/aid-config
```

AID asks a few setup questions (project name, description) and confirms before
writing anything.

**What is produced:**

```
tasktracker/
  .aid/
    settings.yml          ← project config (project name, discovery.doc_set, etc.)
    knowledge/
      STATE.md            ← discovery-area state ledger (starts empty)
      architecture.md     ← placeholder (14 standard KB templates seeded)
      coding-standards.md
      domain-glossary.md
      ... (11 more standard KB docs, all empty placeholders)
      INDEX.md
      README.md
  CLAUDE.md               ← context file for Claude Code (or AGENTS.md for other tools)
```

**Note for greenfield:** Because there is no existing codebase, you do NOT run
`aid-discover`. Discovery is the Knowledge Base construction phase — it analyzes an
existing codebase. On a greenfield project, the KB starts empty and gets populated
incrementally as you build. Skip straight to Interview.

> Sample `.aid/settings.yml` excerpt: [settings.yml](samples/settings.yml)

---

## 3. Step 2 — Run the Interview

**Skill:** `aid-describe`
**Why:** Interview is where AID elicits the work definition. It asks structured
questions about what you want to build, who uses it, quality requirements, and
constraints — then produces the formal requirements and feature structure for the
full path (or a condensed SPEC for the lite path).

**What you do:**

```
/aid-describe
```

The interviewer agent leads you through a conversational Q&A. For this project the
questions cover:

- What problem does this solve? Who are the users?
- What are the core capabilities (functional scope)?
- Authentication strategy?
- Data persistence requirements?
- Performance, security, and compliance needs?
- Deployment target?

After the Q&A, `aid-describe` enters TRIAGE (see Step 3) to determine the path.

---

## 4. Step 3 — TRIAGE Decision

**Skill:** `aid-describe` (internal TRIAGE state)
**Why:** TRIAGE evaluates three signals to decide whether the work is small enough
for the lite path or large enough to warrant the full path:

| Signal | Question | This project |
|--------|----------|-------------|
| T1 — Breadth | How many distinct features? | multiple (auth, tasks CRUD, list/filter) → not trivial |
| T2 — Size | Roughly how many distinct tasks will this require? | many (6 or more) → not a few |
| T3 — Type | What kind of work is it? | new feature or system (auth + persistence) → multiple moving parts |

**Result:** T1=multiple + T2=many + T3=new feature or system → TRIAGE routes to the **full path**. (No workType is assigned on the full path.)

For a greenfield project of this scope, the full path is the right choice. The
alternative (lite path) applies when you are adding one small, well-scoped change
to an existing codebase — for example, fixing a single bug or adding a single
endpoint. (See the brownfield lite-path example for that scenario.)

**Full path output from Interview:**

`aid-describe` produces:
- `REQUIREMENTS.md` — the canonical requirements document
- `.aid/work-001-tasktracker-api/features/` — one directory per feature with an
  empty `SPEC.md` stub

> Sample `REQUIREMENTS.md` excerpt: [samples/REQUIREMENTS.md](samples/REQUIREMENTS.md)

---

## 5. Step 4 — Specify Each Feature

**Skill:** `aid-specify`
**Why:** Specification adds the technical layer to each feature's `SPEC.md` stub.
Where the requirements describe _what_ and _why_, the spec describes _how_: data
models, API contracts, component boundaries, error handling, and acceptance criteria
precise enough for a coding agent to implement without ambiguity.

**What you do:**

```
/aid-specify
```

AID reads `REQUIREMENTS.md` and each feature stub, then dispatches specialist agents
to write the technical spec per feature. You review each `SPEC.md` and confirm before
moving on.

**Features specified for this project:**

| Feature | SPEC covers |
|---------|-------------|
| F1 — Authentication | JWT signing, token expiry, password hashing (bcrypt), `/auth/register` + `/auth/login` endpoints, error codes |
| F2 — Task CRUD | `tasks` table schema, REST endpoints (POST/GET/PATCH/DELETE), request/response shapes, validation rules, ownership enforcement |
| F3 — List & Filter | Query parameter schema, filter logic (status, due date range), sort options, pagination (cursor-based), response envelope |

> Sample `SPEC.md` for F2 (Task CRUD): [samples/feature-f2-spec.md](samples/feature-f2-spec.md)

---

## 6. Step 5 — Plan the Deliveries

**Skill:** `aid-plan`
**Why:** Planning sequences the features into deliveries — self-contained, shippable
increments that can be reviewed and merged independently. The plan answers: in what
order do we build, and what does each delivery gate check?

**What you do:**

```
/aid-plan
```

AID reads all `SPEC.md` files, identifies dependencies between features, and proposes
a delivery sequence. You confirm (or adjust) before it is finalized.

**Delivery plan produced:**

| Delivery | Features | Gate criteria |
|----------|----------|---------------|
| D1 | F1 — Authentication | Register + login endpoints green; JWT round-trip test passes; unit tests for password hashing |
| D2 | F2 — Task CRUD | Full CRUD endpoints green; ownership enforcement tested; DB migration applies cleanly |
| D3 | F3 — List & Filter | Filter + sort + pagination endpoints green; edge cases tested (empty result, invalid filter) |

> Sample `PLAN.md` excerpt: [samples/PLAN.md](samples/PLAN.md)

---

## 7. Step 6 — Detail the Tasks

**Skill:** `aid-detail`
**Why:** Detailing breaks each delivery into typed, PR-sized task files. Each task
file is a precise specification for a single unit of work — small enough to implement
in one focused session, with explicit inputs, outputs, and acceptance criteria. This
is what the coding agent reads during execution.

**What you do:**

```
/aid-detail
```

AID reads `PLAN.md` and each `SPEC.md`, then produces `task-NNN.md` files in
`.aid/work-001-tasktracker-api/tasks/`. It also writes an execution graph showing
which tasks can run in parallel vs. must be sequential.

**Tasks produced (D1 — Authentication):**

| Task | Type | What it does |
|------|------|-------------|
| task-001 | IMPLEMENT | Postgres schema migration: `users` table |
| task-002 | IMPLEMENT | `POST /auth/register` endpoint + bcrypt hashing |
| task-003 | IMPLEMENT | `POST /auth/login` endpoint + JWT issuance |
| task-004 | IMPLEMENT | JWT middleware (verify token, attach user to request) |
| task-005 | TEST | Unit tests for password hashing and JWT round-trip |
| task-006 | TEST | Integration tests for register + login endpoints |

> Sample `task-002.md`: [samples/task-002.md](samples/task-002.md)

---

## 8. Step 7 — Execute

**Skill:** `aid-execute`
**Why:** Execution is where the coding agent implements, self-reviews, and iterates
on each task. `aid-execute` runs a two-tier review: a self-review by the implementing
agent, then an independent review by a senior reviewer agent. Work does not move on
until it meets the minimum grade.

**What you do:**

```
/aid-execute
```

AID reads the task files, dispatches the appropriate specialist agents (developer,
data-engineer, etc.), and runs the review loop per task. You are kept in the loop at
phase gates — before merging a delivery, AID presents a gate summary for your
confirmation.

**What happens during execution:**

1. AID reads task-001 (DB migration). The data-engineer agent writes the migration
   file and the schema changes. The reviewer agent grades it. Grade A — approved.
2. AID reads task-002 (register endpoint). The developer agent implements the endpoint.
   Self-review finds a missing input validation for the email field — fixed inline.
   Reviewer grades it B+ (one suggestion: add a test for duplicate email). AID flags
   the suggestion for task-005.
3. ... tasks proceed in the execution graph order, parallel tasks run concurrently
   where the graph allows ...
4. After all D1 tasks complete, AID presents the D1 delivery gate: "All 6 tasks graded
   ≥ B. Gate criteria: JWT round-trip test passes — confirmed. Merge D1?"

**Grading scale:**

| Grade | Meaning |
|-------|---------|
| A+, A, A- | Approved — clean, well-tested |
| B+, B, B- | Approved with minor suggestions (non-blocking) |
| C+, C, C- | Conditional — specific items must be addressed before merge |
| D+, D, D- | Rejected — significant issues; re-implement |
| E+, E, E- | Rejected — a critical-severity finding is present |
| F | Rejected — non-functional (build/run failed) |

The reviewer tier is always ≥ the executor tier (a Large model reviews a Medium model's
work — never the reverse). This invariant is enforced by the agent dispatch system.

**Optional: after execution**

Once the codebase is live, two optional deliver skills are available:

- `/aid-deploy` — packages a release, generates a `package-NNN.md`, and produces a
  `DEPLOYMENT-STATE.md` tracking what was shipped.
- `/aid-monitor` — watches live signals (logs, alerts, metrics), classifies findings,
  and routes bugs to `/aid-describe` via the LITE-BUG-FIX triage (skipping spec/plan),
  and change requests to `/aid-describe` as new or changed requirements (full cycle).

These are optional end-of-pipeline skills. They are not required to complete a
delivery.

---

## 9. What You Get

After the full pipeline, the `tasktracker` project has:

**Artifacts in `.aid/`:**

```
.aid/
  settings.yml
  work-001-tasktracker-api/
    REQUIREMENTS.md
    PLAN.md
    STATE.md
    features/
      f1-authentication/
        SPEC.md
      f2-task-crud/
        SPEC.md
      f3-list-filter/
        SPEC.md
    tasks/
      task-001.md  ...  task-018.md
```

**Code in the project root:**

```
tasktracker/
  src/
    auth/            ← F1: register, login, JWT middleware
    tasks/           ← F2: CRUD endpoints and service layer
    db/              ← migrations, connection pool
    middleware/      ← validation, error handling
  tests/
    unit/            ← password hashing, JWT, validation
    integration/     ← endpoint tests against a test DB
  package.json
  vitest.config.js
```

**Review record:** Each task's review grade and any reviewer suggestions are logged in
the task file itself. The delivery gate summary is in `STATE.md`. This audit trail
shows exactly what was decided at each gate and why.

---

## 10. Key Takeaways

**Greenfield projects skip Discovery.** There is no existing codebase to analyze.
`aid-config` seeds the KB with empty templates; the KB gets populated as you build.

**TRIAGE is automatic.** You do not manually choose the full path. TRIAGE evaluates
your scope (breadth, size, workType) and routes accordingly. For multi-feature work
with non-trivial depth, the full path is the right route.

**Each phase gate is a human checkpoint.** AID proposes; you confirm. Before Specify
locks the technical design, before Plan sequences the deliveries, and before each
delivery merges — you confirm. No phase auto-advances without your sign-off.

**Task files are the unit of trust.** The coding agent reads the task file, implements
it, and the reviewer checks against the task file. If the task file is precise, the
output is predictable. Ambiguity in task files is the leading cause of rework.

**The full path is not overhead for small projects.** The overhead is proportional to
scope: a 3-feature API with auth and persistence benefits from a formal spec and
delivery plan precisely because auth + DB + pagination have subtle interaction effects
that a task list alone cannot capture.
