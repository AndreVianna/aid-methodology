# Behavioral Spec — `show-dashboard` → `dashboard` artifact reframe (task-008)

> **Status:** LOCKED for implementation (design agreed 2026-07-15).
> **Tracked under:** `.aid/work-005-lite-skills-refactor/` (branch `work-005-lite-skills-refactor`).
> **Scope:** `aid-show-dashboard` → reframed as the `dashboard` artifact under create/change.
> A **naming/topology** fix, not a behavior change. Surfaced by the second classification
> re-examination.
> **Not implemented yet.**

---

## 1. Problem

`show-dashboard` is the same verb-vs-artifact inconsistency as `document` and `test`, and
"show" is misleading — the skill **builds a durable, refreshable BI view**, it doesn't
display one. A **dashboard is an artifact you create and update**, not a verb.

Its **behavior is already correct** (keep-cycle — a durable BI build is a real IMPLEMENT
mutation, side-effect axis ✓). So this is purely a naming/topology fix to complete the
artifact-model consistency (after `test` and `document`).

## 2. The reframe

- **`aid-create-dashboard`** (+ **`aid-add-dashboard`** alias) — build a new dashboard/BI view.
- **`aid-change-dashboard`** (+ **`aid-update-dashboard`** alias) — change an existing one.
- **`aid-show-dashboard`** → **backward-compat hint-alias** of `aid-create-dashboard`
  (still works; routes to the create-dashboard behavior).
- `default_type: IMPLEMENT`, **keep-cycle, engine-driven** (unchanged behavior). Group stays
  **G11** (BI/analyze domain, for discovery).
- Naming: `create`/`change` canonical, `add`/`update` aliases (shipped convention).

## 3. What does NOT change

The behavior: source → visualization → publish/refresh, built as a durable artifact through
the normal plan → approve → `/aid-execute` cycle (the gate is correct — a durable, published
BI view is a real mutation a human approves before it lands). No collapse; no producer
change; the existing scaffolding/behavior carries over under the new names.

## 4. Boundary (unchanged, reaffirmed)

- `aid-create-dashboard` = a **durable, refreshable** BI view (keep-cycle).
- `aid-report` = a **one-time** analysis + insight (collapse).
  The `aid-report` spec already draws this line; the rename makes it clearer
  ("create a dashboard" vs "run a report").

## 5. Files the implementation will touch

1. `shortcut-catalog.yml` — add `aid-create-dashboard`/`aid-add-dashboard`,
   `aid-change-dashboard`/`aid-update-dashboard`; convert `aid-show-dashboard` to a
   hint-alias row.
2. `canonical/skills/` — new create/change-dashboard doorways (generated, engine-driven);
   `aid-show-dashboard` becomes a thin hint-alias.
3. `shortcut-engine.md` — the `dashboard` artifact is engine-driven under create/change
   (it currently reads `analyze-report.md`; keep that as the dashboard build guidance or
   relocate — dashboard is the last engine consumer of that file after review/research/
   report detach).
4. Regenerate: `build-shortcut-skills.py` → `run_generator.py` → dogfood resync.

## 6. Settled decisions

Resolved with the user 2026-07-15:

1. Reframe `show-dashboard` → `aid-create-dashboard` / `aid-change-dashboard` (+ `add`/
   `update` aliases); `aid-show-dashboard` → backward-compat hint-alias.
2. **Keep-cycle, behavior unchanged** — naming/topology only, completing the artifact-model
   consistency (test, document, dashboard).
