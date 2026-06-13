# task-041: Front-end reconciliation (index.html) — remove parseWave(), group by task.delivery/lane, neutral phase rail, EXPECTED 2→3

**Type:** IMPLEMENT

**Source:** feature-009-producer-state-emission → delivery-006

**Depends on:** task-040

**Scope:**
- Reconcile `dashboard/index.html` (no-LLM front-end) to the reader's new model shape (task-040), consuming the per-task integer `delivery`/`lane` + `short_name` instead of the invented `delivery-NNN-wave-M` string.
- **Remove `parseWave()`** (the `function parseWave(wave)` matching `^delivery-0*(\d+)-wave-0*(\d+)$` ~line 1452) and every call site in `renderTasksFull` / `renderLanes`. Group deliveries by `task.delivery` (integer) and order lanes by `task.lane`; tasks with `lane == null` go to one "unsequenced" lane within the delivery. The delivery panel label uses the integer `task.delivery` (no more `parsed ? parsed.delivery : 0` → `Delivery #0`).
- **uiState lane key (delivery-scoped, NEW):** `uiState.lanes` currently keys on the raw wave string (`"delivery-002-wave-2"`, ~line 874 / `renderLanes` `lKey = String(t.wave)`). Replace with `"d" + delivery + "-lane" + lane` (e.g. `"d2-lane2"`) and `"d" + delivery + "-unseq"` for the unsequenced lane — delivery-scoped so lane open/collapse state cannot collide across deliveries (lane 1 of delivery-001 vs lane 1 of delivery-002 persist independently). Update the `uiState.lanes` comment.
- **Task chip:** show `task.short_name`, fallback to the `task-NNN` id when `short_name` is null (PF-3/PF-7).
- **Work title fix:** `titleEl.textContent = work.title || work.work_id` (~line 1145) must NOT render the raw `work_id` styled as the authored Name (PF-7); when `title` is absent render the de-slugged work name as an explicitly **labelled / dimmed fallback** (kicker), never the raw `work_id` as the title. The `work_id` kicker in meta (~line 1182) stays.
- **Description / objective:** render Description from the new `work.description` field; PF-2 guarantees no `> _..._` blockquote can leak — verify the description/objective render paths show no blockquote.
- **Phase rail (neutralize "phase unknown"):** in `renderStageRail`, the two `unknownPill.textContent = 'phase unknown'` branches (~lines 1408/1419) must render a **neutral** "phase not yet recorded" state, not a `phase unknown` error badge, when `phase` is null/Unknown/unrecognized (PF-4/PF-7).
- **`EXPECTED_SCHEMA_VERSION` 2 → 3** (~line 854) in lockstep with both servers (task-040); the stale-assets/schema-mismatch banner (~line 978) keeps failing loud on any mismatch (R2).
- Front-end stays no-LLM; this is the single `index.html` writer in this delivery (no write race).

**Acceptance Criteria:**
- [ ] `parseWave()` and all its call sites are removed; tasks group by integer `task.delivery` and order lanes by `task.lane`; `lane == null` → one "unsequenced" lane within the delivery; **no** `Delivery #0` label appears for real data (PF-5).
- [ ] `uiState.lanes` is keyed `"d<delivery>-lane<lane>"` / `"d<delivery>-unseq"`; lane open/collapse persists independently across deliveries (no cross-delivery key collision).
- [ ] Task chips show `task.short_name`, falling back to the `task-NNN` id when null (PF-3/PF-7).
- [ ] The work-overview title renders `work.title`; when `title` is absent it shows a labelled/dimmed de-slug fallback, never the raw `work_id` styled as the Name (PF-7); the description renders from `work.description` with no `> _..._` blockquote leak (PF-2).
- [ ] The phase rail renders a neutral "phase not yet recorded" state (not a `phase unknown` badge) when `phase` is null/Unknown/unrecognized (PF-4/PF-7).
- [ ] `EXPECTED_SCHEMA_VERSION` is `3`; the schema-mismatch banner still fires on any envelope/EXPECTED mismatch (R2).
- [ ] All §6 quality gates pass; rendered behavior is Playwright-validated by task-045 (and the fixture pass by task-042) — this task adds the front-end change only.
