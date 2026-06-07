# Example: Brownfield Lite Path — Fixing a Stale Cache Bug

This tutorial walks through a realistic small change on an existing codebase using
the **AID lite path**. You will see:

- How `/aid-interview` TRIAGE routes a small, well-scoped bug fix away from the full
  pipeline and onto the lite path.
- What the condensed four-state lite flow looks like in practice
  (CONDENSED-INTAKE → TASK-BREAKDOWN → LITE-REVIEW → LITE-DONE).
- What artifacts the lite path produces — and, just as importantly, what it skips.
- How to hand off to `/aid-execute` once the lite gate passes.

The worked scenario is deliberately small: a single bug in a Python web service.
That is intentional — the lite path is designed for work that fits comfortably in
one to three tasks and does not need the full Define → Map chain.

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

Before opening the interview, ask: does the team have a reasonably current Knowledge
Base? This matters because the lite path skips a full discovery run.

In this scenario the KB was built three weeks ago and the relevant module
(`orders_cache.py`, `order_repository.py`) has not changed structurally since then.
The bug is in a well-understood location; no new external integrations are involved.

**Decision: skip re-discovery.** Running `/aid-housekeep` could be used to check
for KB drift if there were any doubt, but here the existing KB is sufficient.

> If the KB were stale or the bug were in an unfamiliar subsystem, the right move
> would be to run `/aid-discover` first (or `/aid-housekeep` for a targeted refresh)
> before opening the interview.

---

## Step 2 — Open the Interview

With the existing KB in place, run:

```
/aid-interview
```

`aid-interview` reads the current `.aid/` state. Because no work is in progress,
it enters its opening state and immediately moves to **TRIAGE**.

---

## Step 3 — TRIAGE: The 2-3 Routing Questions

TRIAGE is deterministic. `aid-interview` asks 2-3 questions in order. Any
"large" answer routes the work to the full pipeline.

**T1 — Breadth: how many distinct features does this work touch?**

> "None — it is a bug fix in a single, well-understood location."

Answer: **none.** Signal: small. (Lite admits `none` or `one small`; `multiple` → FULL.)

**T2 — Size: roughly how many distinct tasks will this require?**

> "A few. The fix is adding an explicit `cache.invalidate(order_id)` call
> in the update path and writing a regression test — two tasks at most."

Answer: **a few (≤ ~5).** Signal: small. (Threshold: `a few` for lite; `many` → FULL.)

**T3 — Type: what category of work is this?**

> "It is a bug fix. The feature is already supposed to work — we are correcting
> a defect, not adding new behaviour."

Answer: **bug-fix.** workType: `bug-fix`. Routes to sub-path: **LITE-BUG-FIX**.

**TRIAGE verdict: LITE path, LITE-BUG-FIX sub-path.**

All three signals pointed to "small." If any one of them had come back "large" —
say, the bug turned out to touch five modules, or the fix required a new caching
strategy — TRIAGE would have routed to the full path instead, and `aid-interview`
would have proceeded to produce `REQUIREMENTS.md` + per-feature `SPEC.md` stubs.

> The lite path is conservative by design. Any ambiguous answer routes full.
> You can always escalate a lite work to full mid-flight; the STATE.md carries
> an `## Escalation Carry` block to preserve slot answers so nothing is re-asked.

---

## Step 4 — CONDENSED-INTAKE: Filling the Spec Slots

Having confirmed the lite path, `aid-interview` invokes the `interviewer` agent
in **CONDENSED-INTAKE** state. Instead of the full multi-session requirements
gathering that the full path uses, CONDENSED-INTAKE is a focused slot-fill:
a short conversation that gathers only what is needed to write the work-root
`SPEC.md`.

The `interviewer` asks targeted questions:

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

CONDENSED-INTAKE ends when the `interviewer` has enough to write the spec. The
`interviewer` then drafts the **work-root SPEC.md** and presents it for approval.

---

## Step 5 — Work-Root SPEC.md (Sample Output)

The `interviewer` produces a single `SPEC.md` at the work root. Notice what is
absent: there is no `REQUIREMENTS.md`, no `features/` folder, and no `PLAN.md`.
The lite path collapses all of that into one document.

See [sample-spec.md](sample-spec.md) for the exact file produced at this step.

The Director reviews it: the problem statement matches the reported bug; the
acceptance criteria are testable; there are no open questions. **Approved.**

---

## Step 6 — TASK-BREAKDOWN: The Architect Proposes Tasks

With the SPEC approved, `aid-interview` invokes the `architect` agent in
**TASK-BREAKDOWN** state. The architect reads the work-root SPEC.md and proposes
a typed task breakdown directly — no PLAN.md sequencing step, no per-feature
decomposition. For a LITE-BUG-FIX, the architect typically produces one to two
tasks.

The architect proposes:

| # | Type | Title |
|---|------|-------|
| task-001 | IMPLEMENT | Add cache invalidation call to `update_order()` + unit test |
| task-002 | TEST | Integration test — update → read cycle confirms fresh data |

Two tasks. task-002 depends on task-001. The task files are written to
`.aid/work-001-fix-stale-cache/tasks/`.

See [sample-task-001.md](sample-task-001.md) for what a lite-path task file looks
like.

> For a LITE-BUG-FIX, the architect aims for exactly 1 IMPLEMENT task (fix +
> regression test). Here the integration test is separated to keep task-001
> reviewable in isolation, which is a judgment call the architect documents in
> its reasoning. Both options (1 task or 2) are valid.

---

## Step 7 — LITE-REVIEW: The Reviewer Validates the Task Set

Before handing off to execute, `aid-interview` runs the **LITE-REVIEW** gate.
The `reviewer` agent reads the work-root SPEC.md and the proposed tasks and
checks:

- Do the tasks cover all acceptance criteria in the SPEC?
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

The default minimum grade for LITE-REVIEW is **A**. B+ does not clear A.

The `reviewer` flags the findings. `aid-interview` presents them to the Director.

**Decision:** Accept the LOW/MINOR fixes — they are quick and clarify intent.
The architect updates task-001 and task-002 in place. The reviewer re-checks the
changed sections only and confirms: grade now **A+** (zero findings remaining).
Gate passes.

> The LITE-REVIEW gate mirrors the rigor of a full-path delivery gate, just scoped
> to the lite task set. The grade scale and severity tags are identical across both
> paths — `[CRITICAL] [HIGH] [MEDIUM] [LOW] [MINOR]` — and the same `grade.sh`
> script computes the letter grade.

---

## Step 8 — LITE-DONE: Hand-Off to Execute

With the LITE-REVIEW gate passed, `aid-interview` enters **LITE-DONE** and emits
the hand-off prompt:

```
Lite path complete. Work: work-001-fix-stale-cache
Tasks ready:
  task-001 — IMPLEMENT — Add cache invalidation call + unit test
  task-002 — TEST      — Integration test, depends on task-001

Run /aid-execute to begin execution on branch aid/work-001-fix-stale-cache-delivery-001.
```

The STATE.md is updated: `Path: lite`, `Status: Ready`, phase gate reached.

---

## Step 9 — Execute

```
/aid-execute
```

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
| `REQUIREMENTS.md` | Yes | No |
| `features/` folder | Yes | No |
| per-feature `SPEC.md` | Yes | No |
| `PLAN.md` | Yes | No |
| work-root `SPEC.md` | No | **Yes** |
| `tasks/task-NNN.md` | Yes (via aid-detail) | **Yes (via TASK-BREAKDOWN)** |
| `STATE.md` | Yes | **Yes** |
| LITE-REVIEW gate | No | **Yes** |
| Delivery gate in execute | Yes | **Yes** |

The lite path eliminated `aid-specify`, `aid-plan`, and `aid-detail` entirely.
For a bug fix that is well understood and confined to one subsystem, those phases
add overhead without adding information. The lite path reaches the same execution
quality bar through a shorter, targeted route.

---

## Recipe Shortcut (Optional)

For recurring patterns like this bug fix, AID ships seed recipes at
`canonical/recipes/`. The `bug-fix.md` recipe is a pre-filled template with
`{{slot}}` placeholders. Its frontmatter declares four slots
(`bug-title`, `bug-description-one-sentence`, `reproduction-steps`,
`intended-behavior`) and the body contains `## spec` and `## tasks` blocks
with those placeholders in place.

To use it, the `interviewer` agent fills a JSON file with the slot values for
this specific bug and calls `parse-recipe.sh`:

```
bash canonical/scripts/interview/parse-recipe.sh \
  --render \
  --recipe canonical/recipes/bug-fix.md \
  --slots-json /path/to/slots.json \
  --work-dir .aid/work-001-fix-stale-cache
```

where `slots.json` contains:

```json
{
  "bug-title": "Stale cache on order update",
  "bug-description-one-sentence": "update_order() never calls cache.invalidate(), so reads return stale status for up to 30 minutes after an update.",
  "reproduction-steps": "1. Update order status to fulfilled. 2. Read order within 30 min. 3. Response shows 'processing'.",
  "intended-behavior": "Read immediately after update returns the updated status."
}
```

The script writes a rendered `SPEC.md` and `tasks/task-001.md` directly into the
work directory, skipping CONDENSED-INTAKE entirely. The recipe output feeds
directly into TASK-BREAKDOWN.

If this codebase produces cache-invalidation bugs regularly, the team could author
a custom recipe with an even tighter slot set specific to that pattern — reducing
the slot-fill step to filling three or four known fields.

Recipes are an optional accelerator. They do not change the lite path mechanics —
the LITE-REVIEW gate still runs, and `/aid-execute` still applies its full
two-tier review.

---

## Summary: The Lite Path in Four States

```
/aid-interview
      │
      ▼
[TRIAGE]
  T1: breadth = none (bug fix)      ──►  small
  T2: size = a few tasks            ──►  small
  T3: type = bug-fix                ──►  workType: bug-fix
                                     sub-path: LITE-BUG-FIX
      │
      ▼
[CONDENSED-INTAKE]  (interviewer agent)
  Slot-fill conversation → work-root SPEC.md
  Director approves SPEC.md
      │
      ▼
[TASK-BREAKDOWN]  (architect agent)
  Proposes 1–2 typed tasks directly from SPEC
  Tasks written to tasks/task-NNN.md
      │
      ▼
[LITE-REVIEW]  (reviewer agent)
  Validates tasks against SPEC
  Grade ≥ minimum (default A) required to pass
  Findings fixed in-place; re-check on changed sections
      │
      ▼
[LITE-DONE]
  Hand-off prompt emitted
  STATE.md updated: Path: lite, Status: Ready
      │
      ▼
/aid-execute
  Two-tier review applies (quick-check + delivery gate)
  Branch: aid/work-001-fix-stale-cache-delivery-001
```

The full path inserts `aid-specify` → `aid-plan` → `aid-detail` between TRIAGE
and execute. The lite path skips all three, replacing them with CONDENSED-INTAKE
+ TASK-BREAKDOWN + LITE-REVIEW — a single `aid-interview` session.

---

## Files in This Example

| File | What it is |
|------|-----------|
| `README.md` | This tutorial |
| `sample-spec.md` | Sample work-root SPEC.md produced at Step 5 |
| `sample-task-001.md` | Sample task file produced at Step 6 |

The sample files are illustrative outputs, not real project files. They show the
exact shape and sections AID produces; the content is specific to this scenario.
