# task-039: /aid-detail PF-3 descriptive task short-name rule + PF-5a normalized wave-map emission in PLAN.md

**Type:** IMPLEMENT

**Source:** feature-009-producer-state-emission → delivery-006

**Depends on:** —

**Scope:**
- PF-3 (guardrail, no format change) in `canonical/skills/aid-detail/references/task-decomposition.md` (`## Task File Format`, the `# task-NNN: {Title}` line already at line 1): add an explicit rule that `{Title}` MUST be a **descriptive short-name** — a noun phrase naming the deliverable of the task — not a restatement of the task `Type` and not a bare `task-NNN` id; and a note that `/aid-execute` **preserves** the title line on any task-file update. This is the short-name the reader (task-040) parses via `^#\s+task-0*\d+\s*:\s*(.+)$`.
- PF-5a (NEW producer format) in `canonical/skills/aid-detail/references/execution-graph-generation.md` (Step 5, alongside the existing human-facing `| Task | Depends On |` / parallel tables): under each `### delivery-NNN execution graph`, additionally emit a fenced typed **```wave-map``` block** with a `delivery: NNN` line and one `wave N: <comma-separated task ids>` line per wave/lane — deterministic, total, no inference — so the reader builds `task_id → {delivery: NNN, lane: N}` as a table lookup. Where a wave has parallel sub-lanes, one `wave N:` line per sub-lane is permitted (carries the lane distinction the prose loses). Keep the existing prose/dependency tables (human-facing) unchanged.
- Edits are **ASCII-only** (the fenced format characters used are ASCII; do not introduce non-ASCII), **behavior-preserving / additive** (C4/C5 — only adds emitted content, does not change `/aid-detail` ordering/decomposition behavior). Edits `canonical/skills/**` only; the dogfood render is task-043 (do NOT edit `.claude/skills/**` here).

**Acceptance Criteria:**
- [ ] `task-decomposition.md` states the `# task-NNN: {Title}` line must be a descriptive short-name (noun phrase naming the deliverable; not the Type; not a bare id) and that `/aid-execute` preserves the title (PF-3); the documented shape parses under `^#\s+task-0*\d+\s*:\s*(.+)$`.
- [ ] `execution-graph-generation.md` Step 5 emits a ` ```wave-map``` ` block per `### delivery-NNN execution graph` containing a `delivery: NNN` line and `wave N: <ids>` lines, alongside (not replacing) the existing human-facing graph tables (PF-5a); the documented block parses to a deterministic `task_id → {delivery, lane}` map.
- [ ] All touched canonical files are ASCII-only; the edits add emitted content only and change no `/aid-detail` phase, gate, advance, or decomposition decision (C4/C5).
- [ ] All §6 quality gates pass; the canonical edit is left to be dogfood-rendered by task-043 (this task does not run `run_generator.py` and does not modify `.claude/skills/**`).
