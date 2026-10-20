# Example: Brownfield Lite Path — Fixing a Stale Cache Bug

This tutorial walks through a realistic small change on an existing codebase using
the **AID lite path**. You will see:

- How a direct-entry shortcut (`/aid-fix`) takes a small, well-scoped bug fix straight
  to a graded Lite work, without the full pipeline.
- What the shortcut engine does in one run: capture, specification, task breakdown,
  grading and an approval.
- What artifacts the lite path produces — and, just as importantly, what it skips.
- How to hand off to `/aid-execute` once you approve.

The worked scenario is deliberately small: a single bug in a Python web service.
That is intentional — the lite path is designed for work that fits comfortably in
one to three tasks and does not need the full Define → Plan chain.

---

## Scenario

**Codebase:** `orders-api` — a Python/FastAPI service that manages customer orders
for an e-commerce platform. It has been in production for two years. The Knowledge
Base was built during a previous AID discovery cycle and lives at `.aid/knowledge/`.

**The problem reported by QA:** After a surge in order volume, the order-status
endpoint occasionally returns stale data. Investigation points to the in-memory
cache never being invalidated when an order is updated. Orders show a status of
`"processing"` even after the database record has been marked `"fulfilled"`.

**Change request:** Fix the cache invalidation bug in `orders_cache.py`.

---

## Step 1 — Decide Whether to Run `/aid-discover` First

Before you start, ask: does the team have a reasonably current Knowledge
Base? This matters because the lite path skips a full discovery run.

In this scenario the KB was built three weeks ago and the relevant module
(`orders_cache.py`, `order_repository.py`) has not changed structurally since then.
The bug is in a well-understood location; no new external integrations are involved.

**Decision: skip re-discovery.** Running `/aid-housekeep` could be used to check
for KB drift if there were any doubt, but here the existing KB is sufficient.

> If the KB were stale or the bug were in an unfamiliar subsystem, the right move
> would be to run `/aid-discover` first (or `/aid-housekeep` for a targeted refresh)
> before asking for the fix.

---

## Step 2 — Ask for the Fix

With the existing KB in place, say what you want, either in plain words or with the
shortcut that matches the request:

```
/aid-fix the order-status endpoint returns stale data after an update
```

`/aid-fix` is one of the verb-first shortcut skills. It is bound to the verb `fix`, so
it already knows the shape of the change and skips the generic questions a
from-scratch requirements interview would ask. It creates a flattened Lite work:
one feature, one delivery, nothing to sequence, so no plan is written.

> If the request were large (several features, many tasks) or unclear, the right
> move would be the full path: `/aid-describe` gathers the requirements, and
> `/aid-define`, `/aid-specify`, `/aid-plan` and `/aid-detail` follow.

---

## Step 3 — Capture: A Few Short Questions

The shortcut asks only what it needs to write the requirements, one question at a
time, each with its reason and a recommendation. For this bug it asks:

1. **What is the root cause as you understand it?**
   > "The `update_order()` function in `order_repository.py` modifies the database
   > record but never calls `orders_cache.invalidate()`. Any cached entry for that
   > order persists until TTL expiry (30 minutes)."

2. **What is the expected correct behaviour?**
   > "Immediately after a successful database write, the cache entry for that
   > `order_id` must be invalidated. Subsequent reads should hit the database
   > and re-populate the cache with fresh data."

3. **Are there regression test requirements?**
   > "Yes. A unit test that mocks the cache and confirms `invalidate()` is called
   > on every `update_order()` execution, and an integration test that exercises
   > the full update → read cycle."

4. **Any constraints?** (backwards compatibility, deployment concerns)
   > "None. `invalidate()` already exists on the cache class; this is a call-site
   > omission, not a missing feature."

---

## Step 4 — Work-Root REQUIREMENTS.md (Sample Output)

The `aid-architect` agent writes a single `REQUIREMENTS.md` at the work root. Its
section 11 carries the one feature's technical specification and section 9 carries
the gate criteria. Notice what is absent: there is no `features/` folder and no
`PLAN.md`. The lite path collapses all of that into one document.

See [sample-requirements.md](sample-requirements.md) for the exact file produced at this step.

---

## Step 5 — The Task Breakdown

The architect reads the work-root `REQUIREMENTS.md` and writes a typed task
breakdown directly — no per-feature decomposition. For a bug fix it typically
produces one to two tasks.

| # | Type | Title |
|---|------|-------|
| task-001 | IMPLEMENT | Add cache invalidation call to `update_order()` + unit test |
| task-002 | TEST | Integration test — update → read cycle confirms fresh data |

Two tasks. task-002 depends on task-001. Each task is written to
`.aid/works/work-001-fix-stale-cache/tasks/task-NNN/DETAIL.md`, and the execution
order is derived from each task's `**Depends on:**` field.

See [sample-task-001.md](sample-task-001.md) for what a lite-path task file looks
like.

> For a bug fix, the architect aims for exactly 1 IMPLEMENT task (fix + regression
> test). Here the integration test is separated to keep task-001 reviewable in
> isolation, which is a judgment call the architect documents in its reasoning.
> Both options (1 task or 2) are valid.

---

## Step 6 — The Grading Gates

Before it shows you anything, the shortcut grades its own documents, in two passes:
the requirements first, then the task set. The `aid-reviewer` agent checks:

- Do the tasks cover all acceptance criteria in the requirements?
- Are the task types correct?
- Are the dependencies correctly declared?
- Is anything overcomplicated for the stated change?

The reviewer in this scenario finds two minor points and one issue:

- `[MINOR]` task-001 Scope does not explicitly name the file path
  `order_repository.py` — add it so the executor has no ambiguity.
- `[MINOR]` task-002 Scope references "integration test" without naming the test
  module — specify `tests/integration/test_order_update.py`.
- `[LOW]` task-001 Acceptance Criteria do not state the mock assertion pattern —
  add "assert `cache.invalidate` is called with `order_id` as the only argument."

No HIGH or CRITICAL findings. The computed grade is **B+** (worst severity is LOW;
1 LOW finding → B tier, count = 1 → `+` modifier → B+).

The default minimum grade is **A**. B+ does not clear A, so the architect fixes the
findings in place and the reviewer re-checks the changed sections only. The grade is
now **A+** (zero findings remaining), and the gate passes.

> The gates mirror the rigor of a full-path delivery gate, just scoped to the lite
> work. The grade scale and severity tags are identical across both paths —
> `[CRITICAL] [HIGH] [MEDIUM] [LOW] [MINOR]` — and the same `grade.sh` script computes
> the letter grade.

---

## Step 7 — Your Approval

The shortcut shows you the work it made: the requirements, the task list and the
grades. It asks one question, whether you approve it, with its recommendation. It
never starts building on its own. You can approve, ask for a change to the
requirements or to the task set, or drop the work.

In this scenario you approve. The work's record is updated with the approval, and
the work is ready to execute.

---

## Step 8 — Execute

Ask to carry on with the work (`/aid-execute` runs it).

`aid-execute` reads `tasks/`. It detects two tasks with a dependency edge
(task-002 depends on task-001). It runs task-001 first, runs the built-in
quick-check review, then dispatches task-002. After both tasks complete, the
delivery gate runs a full review. The gate passes (grade A). The branch
`aid/work-001-fix-stale-cache-delivery-001` is ready for a PR.

The full path's two-tier review model — per-task quick-check + per-delivery gate
— applies unchanged on the lite path. The lite path compresses the *planning*
phases; it does not relax the *execution quality* bar.

---

## What the Lite Path Produced vs. What It Skipped

| Artifact | Full Path | Lite Path (this example) |
|----------|-----------|--------------------------|
| work-root `REQUIREMENTS.md` | Yes | **Yes** |
| per-feature `### Feature NNN` section under `REQUIREMENTS.md § 11` | One per feature | **One (feature-001)** |
| `PLAN.md` | Yes | No |
| `tasks/task-NNN/DETAIL.md` | Yes (via aid-detail) | **Yes (written by the shortcut)** |
| `STATE.yml` (the work's record) | Yes | **Yes** |
| Grading gates before approval | Per document | **Yes (requirements, then task set)** |
| Delivery gate in execute | Yes | **Yes** |

The lite path eliminated separate `aid-describe`, `aid-define`, `aid-specify`, `aid-plan`
and `aid-detail` runs. For a bug fix that is well understood and confined to one
subsystem, those phases add overhead without adding information. The lite path reaches
the same execution quality bar through a shorter, targeted route.

---

## Summary: The Lite Path in One Run

```
/aid-fix <the request>
      │
      ▼
Capture: a few short questions, one at a time
  → work-root REQUIREMENTS.md (section 11 = the one feature's spec)
      │
      ▼
Task breakdown (aid-architect)
  Proposes 1–2 typed tasks directly from the requirements
  Tasks written to tasks/task-NNN/DETAIL.md
      │
      ▼
Grading gates (aid-reviewer)
  Requirements, then task set
  Grade ≥ minimum (default A) required to pass
  Findings fixed in place; re-check on changed sections
      │
      ▼
Your approval
  Nothing is built before you approve
      │
      ▼
/aid-execute
  Two-tier review applies (quick-check + delivery gate)
  Branch: aid/work-001-fix-stale-cache-delivery-001
```

The full path runs `aid-describe`, `aid-define`, `aid-specify`, `aid-plan` and
`aid-detail` one after another before execute. The lite path replaces them with one
shortcut run.

---

## Files in This Example

| File | What it is |
|------|-----------|
| `README.md` | This tutorial |
| `sample-requirements.md` | Sample work-root REQUIREMENTS.md produced at Step 4 |
| `sample-task-001.md` | Sample task file produced at Step 5 |

The sample files are illustrative outputs, not real project files. They show the
exact shape and sections AID produces; the content is specific to this scenario.
