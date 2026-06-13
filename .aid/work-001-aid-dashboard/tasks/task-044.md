# task-044: Migrate work-001 to the canonical schema (PF-1 header, typed Pipeline Status, PLAN wave-map transcription)

**Type:** MIGRATE

**Source:** feature-009-producer-state-emission → delivery-006

**Depends on:** task-040, task-043

**Scope:**
- One-time, in-place content migration of work-001's pre-feature artifacts to the canonical schema (FR26 — the bootstrap case). No behavior change; the migrated repo must read clean under the reconciled reader (task-040) with the dogfood-rendered producers (task-043).
- `.aid/work-001-aid-dashboard/REQUIREMENTS.md`: insert the PF-1 identity header (`- **Name:** AID Live Dashboard` + a confirmed **one-sentence Description derived from the `## 1. Objective`**) between `# Requirements` and `## Change Log`. The `> _Status: Complete — approved._` blockquote under `## 1. Objective` **stays** (reader skips it per PF-2).
- `.aid/work-001-aid-dashboard/STATE.md`: add the typed `## Pipeline Status` block (feature-001 shape) with `Lifecycle: Running`, `Phase: Execute`, `Active Skill: none`, `Updated: {UTC}`, `Pause Reason: —`, `Block Reason: —`. Keep the legacy `> **Status:** ...` / `> **Phase:** Execute` blockquote header (harmless content history; the normalized reader ignores it — PF-4).
- `.aid/work-001-aid-dashboard/PLAN.md`: under each `### delivery-NNN execution graph`, add a ` ```wave-map``` ` block (PF-5a) transcribed from the existing `- Wave N:` prose, **one `wave N:` line per sub-lane** where the prose has parallel sub-lanes (e.g. delivery-001's feature-001 lane / feature-002 lane; delivery-002's PT-1 / front-end / CLI lanes), so work-001 uses the normalized path and recovers the sub-lane fidelity the prose parser flattens. Cover **every** delivery that has an `### delivery-NNN execution graph` in PLAN.md — deliveries 001–006 (PLAN includes delivery-004 and delivery-005 graphs), consistent with the AC.
- `tasks/task-NNN.md`: titles are already descriptive `# task-NNN: <title>` — **verify** each first line parses under `^#\s+task-0*\d+\s*:\s*(.+)$`; fix any bare/non-descriptive title. No change expected.
- `settings.yml`: no change — value is already `AID`; PF-6 strips the inline comment reader-side.

**Acceptance Criteria:**
- [ ] `REQUIREMENTS.md` carries the PF-1 header (`- **Name:** AID Live Dashboard` + a one-sentence Description from the Objective) between `# Requirements` and `## Change Log`; the `> _Status:_` blockquote remains in `## 1. Objective`.
- [ ] `STATE.md` carries a typed `## Pipeline Status` block (`Lifecycle: Running`, `Phase: Execute`, Active Skill / Updated / Pause Reason / Block Reason populated); the legacy blockquote header is retained and ignored by the normalized reader.
- [ ] `PLAN.md` has a `wave-map` block per delivery transcribed from the prose, with one `wave N:` line per parallel sub-lane; every task id in each delivery's prose graph appears in its wave-map.
- [ ] Every `tasks/task-NNN.md` first line parses to a descriptive short-name (PF-3); any bare/non-descriptive title fixed.
- [ ] Reading the migrated work-001 repo under `read_repo` (both runtimes) yields real Name/Description/Objective (no leaked blockquote), `Phase: Execute`, real delivery grouping (deliveries 001–006 with correct lanes from the wave-map), real task short-names, and **zero** PF-7 garbage sentinels; both runtimes byte-identical.
- [ ] All §6 quality gates pass.
