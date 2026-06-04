# Tutorial: Brownfield Project — Full Path

This tutorial walks through applying AID to an **existing codebase** using the **full
path**: `aid-discover` first (to build a Knowledge Base from the existing code), then
`aid-interview` → `aid-specify` → `aid-plan` → `aid-detail` → `aid-execute`.

If your project is small and the change is well-scoped, see the
[brownfield lite-path example](../brownfield-lite-path/README.md) instead.

---

## Sample project: OrderFlow API

**OrderFlow** is a Node.js/PostgreSQL order management backend for a mid-size
e-commerce company. It has been in production for three years. It has:

- ~18,000 lines of JavaScript across 90 source files
- PostgreSQL 13 as the primary store (Sequelize ORM, no migrations tool, schema
  drift detected)
- A REST API serving two downstream clients (a React storefront and a mobile app)
- No architecture documentation; domain rules live only in code comments and
  tribal knowledge
- A growing backlog of bugs traced to misunderstood order-state transitions
- A new requirement: add a **Refund** workflow (a state machine across three tables
  with idempotency requirements and webhook notifications)

The Refund feature is substantial — it touches the order-state machine, introduces a new
table, and must integrate with an external payment processor. This is not a small change,
so the full path is appropriate.

---

## Step 0 — Install AID into the project

If AID is not yet installed in OrderFlow, run the setup script from the AID repo root:

```bash
bash setup.sh
```

The interactive menu lists the five supported AI coding tools. Select the tool(s) you
use and choose **Done**:

```
AID Setup — select your AI coding tools
  1) Claude Code
  2) OpenAI Codex CLI
  3) Cursor
  4) GitHub Copilot CLI
  5) Antigravity
  6) Done
```

The installer copies the selected profile(s) into your project. For Claude Code, this
produces a `.claude/` directory containing skills, agents, and a `CLAUDE.md` context
file. For other tools the output directory differs (Codex: `.codex/` + `.agents/`;
Cursor: `.cursor/`; Copilot CLI: `.github/`; Antigravity: `.agent/`).

Then run `aid-config` to initialize the AID work area inside OrderFlow:

```
/aid-config
```

**What `aid-config` does:**

- Creates the `.aid/` directory with the required scaffold
- Seeds `.aid/knowledge/` with 14 blank KB document templates and 3 meta-files
  (`INDEX.md`, `README.md`, `STATE.md`)
- Creates `CLAUDE.md` (or `AGENTS.md`, depending on your tool) with context
  pointers for the AI agent

At this point `.aid/knowledge/` exists but every document is empty — Discovery will
fill them.

---

## Step 1 — Discovery: build the Knowledge Base

This is the defining step of the brownfield full path. Running `aid-discover` on an
existing codebase produces a 14-document Knowledge Base that captures what the project
actually does — architecture, module structure, coding conventions, tech debt, domain
rules — derived from the code itself, not from what anyone remembers.

```
/aid-discover
```

**What `aid-discover` does:**

1. Generates a `project-index.md` pre-pass (file tree + line counts per module) so
   downstream agents have a navigational map of the codebase.
2. Dispatches six specialist sub-agents in parallel — `discovery-scout`,
   `discovery-architect`, `discovery-analyst`, `discovery-integrator`,
   `discovery-quality`, `discovery-reviewer` — each reading a different slice of the
   source code.
3. Proposes the KB doc-set for this project (Step 0d). Because OrderFlow has a REST
   API and a PostgreSQL schema, the proposed doc-set includes all 14 standard
   documents. You confirm or adjust the list before agents write.
4. Each sub-agent writes to a subset of the KB documents. The `discovery-reviewer`
   grades each document and records open questions in `.aid/knowledge/STATE.md`.
5. Q&A: the skill surfaces questions that require human input — things the code
   cannot answer alone (e.g., "Is the `PENDING` state meant to be re-entrant after
   a payment failure?"). You answer each question; answers are appended to `STATE.md`
   and incorporated into the KB.

**Key outputs for OrderFlow:**

- `.aid/knowledge/architecture.md` — the four-layer architecture (API router →
  service layer → Sequelize ORM → PostgreSQL), async job queue for notifications
- `.aid/knowledge/module-map.md` — 90 files categorized into 8 modules (auth,
  orders, inventory, payments, notifications, reports, admin, shared)
- `.aid/knowledge/domain-glossary.md` — 31 domain terms extracted from the codebase,
  including the order-state machine (`DRAFT → CONFIRMED → FULFILLED → CANCELLED`)
- `.aid/knowledge/tech-debt.md` — schema drift (3 columns present in DB not in
  Sequelize models), missing migration tooling, one deprecated payment gateway method
- `.aid/knowledge/coding-standards.md` — async/await pattern, error-first middleware
  chain, naming conventions (camelCase everywhere, `*Service.js` suffix pattern)

See [`sample-kb-excerpt.md`](sample-kb-excerpt.md) for an illustrative excerpt of
what `domain-glossary.md` and `tech-debt.md` look like after Discovery.

**Why Discovery pays for itself:** Every subsequent step — Interview, Specify, Execute
— draws directly from this KB. The Refund feature spec will reference the exact
order-state machine documented here; the developer agent will follow the coding
standards captured here. Without Discovery, each step would require re-reading the
codebase from scratch, accumulating the same knowledge inconsistently across agents.

---

## Step 2 — Interview: capture requirements

With the KB in place, `aid-interview` can ask targeted, informed questions. The skill
reads the KB before generating any question — so it already knows the order-state
machine, the payment service interface, and the existing notification pattern.

```
/aid-interview
```

**What `aid-interview` does (TRIAGE first):**

`aid-interview` opens with a TRIAGE sequence — three diagnostic questions to determine
whether the full path or the lite path is appropriate:

- **T1 — Breadth:** "How many distinct features does this work touch?" → For the
  Refund workflow: one feature with cross-cutting impact. Breadth = 1 feature, but
  it is substantial.
- **T2 — Size:** "How long do you estimate this would take a developer without AID?"
  → "At least a week, maybe more." Size = large.
- **T3 — workType:** "Is this a bug fix, small refactor, or new feature?" → "New
  feature with state-machine complexity."

TRIAGE result: **full path**. The skill proceeds to the full Interview state machine.

**The interview produces:**

- `REQUIREMENTS.md` at `.aid/work-NNN/REQUIREMENTS.md` — the scope boundary and
  business requirements for this work item
- A feature stub at `.aid/work-NNN/features/refund-workflow/SPEC.md` — the feature's
  shell, ready for technical specification

**Sample REQUIREMENTS.md structure:**

```
# REQUIREMENTS: Refund Workflow (work-003)

## Scope
Add a Refund state machine to OrderFlow that handles full and partial
refunds, integrates with the Stripe payment gateway, and notifies
downstream clients via webhook.

## Out of Scope
- Partial refunds on bundles (deferred to a future work item)
- Admin UI for manual override (separate feature)

## Business Requirements
BR-1: A refund can only be initiated from FULFILLED or CONFIRMED state.
BR-2: Partial refund amount must not exceed the original payment amount.
BR-3: Refund processing must be idempotent (duplicate webhook delivery safe).
BR-4: Webhook notification to storefront within 60 seconds of processor ACK.
```

---

## Step 3 — Specify: add technical depth to each feature SPEC

`aid-specify` reads the requirements and the KB, then writes the technical
specification for each feature SPEC stub created by Interview.

```
/aid-specify
```

**What `aid-specify` does:**

For each feature stub in `.aid/work-NNN/features/`, the `architect` agent reads:
- The feature's `SPEC.md` stub (business requirements from Interview)
- The relevant KB documents (especially `architecture.md`, `module-map.md`,
  `domain-glossary.md`, `schemas.md`, and `pipeline-contracts.md`)

It then writes the technical specification directly into the feature's `SPEC.md`:
data model changes, API contract additions, integration approach, and acceptance
criteria at the code level.

**For the Refund feature, `aid-specify` produces:**

- A new `refunds` table schema (with `idempotency_key`, `status`, `amount`,
  `order_id`, `stripe_charge_id`, `created_at`, `processed_at`)
- Three new REST endpoints: `POST /orders/:id/refunds`, `GET /orders/:id/refunds`,
  `GET /refunds/:id`
- A state machine diagram for refund states: `PENDING → PROCESSING → SUCCEEDED |
  FAILED`
- Integration contract with the Stripe Refunds API (idempotency-key header usage,
  webhook verification)
- A migration script requirement to add the `refunds` table cleanly

See [`sample-spec-excerpt.md`](sample-spec-excerpt.md) for an illustrative excerpt
of the completed `SPEC.md` for the Refund feature.

**Why specifying from the KB matters:** The spec references the existing
`payments/StripeService.js` module (found in `module-map.md`), follows the
error-first middleware pattern (from `coding-standards.md`), and ensures the new
`REFUNDED` payment state slots correctly into the payment-state machine (not the
order-state machine — those are distinct; see `domain-glossary.md` §Payment States)
without conflicting with the order states `DRAFT/CONFIRMED/FULFILLED/CANCELLED`. An
agent without the KB would have to re-discover all of this — and might get it wrong.

---

## Step 4 — Plan: sequence features into deliveries

`aid-plan` takes the set of specified features and produces a delivery plan that
sequences work into PR-sized deliveries, respecting dependencies.

```
/aid-plan
```

**What `aid-plan` does:**

The `architect` agent reads all feature SPECs and produces `PLAN.md` at
`.aid/work-NNN/PLAN.md`. It identifies dependencies between features, breaks large
features into deliveries, and assigns a priority sequence.

For the Refund workflow (a single feature), the plan breaks it into two deliveries:

- **delivery-001:** Database migration + Sequelize model + service skeleton (no
  business logic yet) — mergeable independently, unblocks delivery-002
- **delivery-002:** State machine implementation + Stripe integration + webhook
  emission + full test coverage

See [`sample-plan-excerpt.md`](sample-plan-excerpt.md) for an illustrative excerpt
of the `PLAN.md`.

**Why planning matters:** A single large PR touching a new table, three new endpoints,
a state machine, and an external integration is hard to review and risky to merge. The
plan produces independently reviewable deliveries. Each delivery maps directly to a
PR that can be reviewed, tested, and merged without blocking the rest.

---

## Step 5 — Detail: break deliveries into typed tasks

`aid-detail` reads the delivery plan and writes individual `task-NNN.md` files for
each delivery, creating the execution graph.

```
/aid-detail
```

**What `aid-detail` does:**

For each delivery in `PLAN.md`, the `architect` agent writes one `task-NNN.md` file
per unit of work under `.aid/work-NNN/tasks/`. Each task file has:

- A **type** (RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE)
- A **scope** — which files it touches
- A **specification** — what it does, cross-referencing the feature SPEC
- An **acceptance criteria** list
- Dependencies on other tasks

**Task breakdown for delivery-001 (migration + model):**

| Task | Type | What |
|------|------|------|
| task-001 | MIGRATE | Write PostgreSQL migration: create `refunds` table with all columns and foreign key to `orders` |
| task-002 | IMPLEMENT | Add Sequelize `Refund` model, associations, and `RefundStatus` enum |
| task-003 | TEST | Unit tests for `Refund` model associations and validations |

**Task breakdown for delivery-002 (state machine + integration):**

| Task | Type | What |
|------|------|------|
| task-004 | IMPLEMENT | `RefundService.js`: create refund, idempotency check, state machine transitions |
| task-005 | IMPLEMENT | Stripe integration in `RefundService.js`: call Stripe Refunds API, handle errors |
| task-006 | IMPLEMENT | Webhook emission: call notification service on refund state change |
| task-007 | IMPLEMENT | REST controllers: `POST /orders/:id/refunds`, `GET` routes, request validation |
| task-008 | TEST | Integration tests: full refund lifecycle, idempotency, failure paths |
| task-009 | TEST | Webhook delivery tests (mock Stripe, verify notification call) |
| task-010 | DOCUMENT | Update API reference documentation for the three new endpoints |

**Why typed tasks matter:** The task type drives which specialist agent `aid-execute`
dispatches. IMPLEMENT and TEST tasks both go to the `developer` agent (TEST is a task
type, not a separate specialist). MIGRATE tasks go to the `data-engineer` agent.
DOCUMENT tasks go to the `tech-writer` agent. Each agent is optimized for its task type.

---

## Step 6 — Execute: implement and review

`aid-execute` picks up each task, dispatches the right specialist agent, and runs a
mandatory two-tier review before moving to the next task.

```
/aid-execute
```

**What `aid-execute` does:**

For each task in the execution graph:

1. The `orchestrator` agent reads the task file and dispatches the appropriate
   specialist (e.g., `data-engineer` for task-001, `developer` for task-004).
2. The specialist agent reads the task spec, the relevant KB documents, and the
   feature SPEC, then implements the work.
3. **Quick-Check** (per task): a Small-tier `reviewer` agent checks the output for
   HIGH+ issues. There is no grade loop at this stage — findings are recorded and
   deferred to the Delivery Gate.
4. **Delivery Gate** (per delivery): a `reviewer` whose tier matches the delivery's
   complexity score (Small/Medium/Large) runs a full review→fix→grade loop. The grade
   must reach the configured minimum (default: A) before the delivery is marked complete.
5. On pass, the orchestrator advances to the next task in the graph.

**For OrderFlow's Refund feature, task-001 (MIGRATE) produces:**

```sql
-- .aid/work-003/migrations/0001_create_refunds.sql
CREATE TABLE refunds (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID NOT NULL REFERENCES orders(id),
    idempotency_key VARCHAR(255) NOT NULL UNIQUE,
    status          VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    amount          INTEGER NOT NULL,  -- cents
    stripe_charge_id VARCHAR(255),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at    TIMESTAMPTZ
);

CREATE INDEX idx_refunds_order_id ON refunds(order_id);
CREATE INDEX idx_refunds_status   ON refunds(status);
```

The `reviewer` agent checks this against `schemas.md` (UUID primary key pattern
matches existing tables), `coding-standards.md` (column naming in snake_case), and
the SPEC requirement for idempotency. It grades the migration B+ and marks the task
done.

**Review gates enforce KB consistency:** If a developer agent had used `INT` for the
primary key (inconsistent with existing `UUID` usage in `module-map.md`), the
reviewer would catch it and require correction before the task closes. The KB is the
reference, not just the task spec.

---

## Step 7 — Optional: Deploy and Monitor

After all tasks are complete and merged, two optional end-of-pipeline skills are
available:

**`/aid-deploy`** — packages the delivery, produces release notes (`package-NNN.md`),
and tracks deployment state in `DEPLOYMENT-STATE.md`.

**`/aid-monitor`** — after deployment, classifies incoming signals (errors, alerts,
user-reported issues) and routes them back: bugs go to a new `aid-interview` work
item; change requests also go to a new `aid-interview`. This closes the feedback loop.

Neither skill is mandatory. Teams that deploy and monitor through other processes can
omit them.

---

## What the full path produces

After completing all six steps for the Refund workflow, OrderFlow has:

| Artifact | Location | Description |
|----------|----------|-------------|
| Knowledge Base (14 docs) | `.aid/knowledge/` | Permanent asset — reused for every future work item |
| REQUIREMENTS.md | `.aid/work-003/` | Scope boundary and business requirements |
| SPEC.md (Refund feature) | `.aid/work-003/features/refund-workflow/` | Full technical specification |
| PLAN.md | `.aid/work-003/` | Delivery sequence with dependency mapping |
| task-001 through task-010 | `.aid/work-003/tasks/` | Typed, PR-sized task files |
| Migration file | Committed to the repo | PostgreSQL migration for `refunds` table |
| `RefundService.js` | Committed to the repo | State machine + Stripe integration |
| REST controllers | Committed to the repo | Three new API endpoints |
| Test files | Committed to the repo | Unit + integration + webhook tests |
| API documentation | Committed to the repo | Updated endpoint reference |

The Knowledge Base is the most durable artifact. Once written by `aid-discover`, it
persists in `.aid/knowledge/` and is reused — without re-running Discovery — for every
subsequent `aid-interview`. The Refund work item is `work-003`; when the next feature
arrives, the team opens with `/aid-interview` (not `/aid-discover` again) and the KB
is already there.

---

## Key brownfield insight

The value of Discovery in a brownfield project is that it makes the AI agents as
informed as an experienced team member before writing a single line of new code. The
KB captures the order-state machine, the existing payment service interface, the
naming conventions, and the schema patterns — all of which the Refund feature must
respect. Agents that lack this context would produce code that works in isolation but
conflicts with the codebase it must integrate into.

---

## Sample artifacts

The following files in this directory are illustrative sample outputs, clearly marked
as such. They show what KB excerpts, feature SPECs, and delivery plans look like in
practice — not exact outputs (AID produces tailored content for each codebase).

- [`sample-kb-excerpt.md`](sample-kb-excerpt.md) — excerpt from `domain-glossary.md`
  and `tech-debt.md` after Discovery
- [`sample-spec-excerpt.md`](sample-spec-excerpt.md) — excerpt from the Refund
  feature `SPEC.md` after `aid-specify`
- [`sample-plan-excerpt.md`](sample-plan-excerpt.md) — excerpt from `PLAN.md` after
  `aid-plan`

---

## Next steps

- Return to the [examples index](../README.md) to compare this with the greenfield
  and lite-path examples.
- Read the [methodology narrative](../../methodology/aid-methodology.md) for a
  deep-dive into each phase.
- Consult the [glossary](../../docs/glossary.md) for any unfamiliar AID terms.
