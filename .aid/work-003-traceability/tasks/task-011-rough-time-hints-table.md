# task-011-rough-time-hints-table: Rough-time-hints table (canonical asset)

**Type:** DOCUMENT

**Source:** feature-001-you-are-here-heartbeat (AC2 input) → delivery-001

**Depends on:** — (none)

**Scope:**
- Author a new canonical file `canonical/skills/rough-time-hints.md` containing a single markdown table that maps **operation classes** (sub-agent names, validation scripts, long tool calls) to **coarse expected-time bands**.
- One row per operation class. Columns: Operation Class · Expected Time Band · Notes.
- Required coverage (at minimum):
  - 6 discovery sub-agents: `discovery-architect`, `discovery-analyst`, `discovery-integrator`, `discovery-quality`, `discovery-scout`, `discovery-reviewer` (each typically 3–5 min when run)
  - Standalone `reviewer` agent (1–2 min)
  - `developer` agent (varies by task type — provide bands for IMPLEMENT vs DOCUMENT vs TEST tasks)
  - `architect` agent (2–4 min)
  - Validation scripts: `validate-html.sh`, `validate-links.sh`, `validate-diagrams.mjs`, `contrast-check.mjs` (~30s each)
  - `/aid-generate` end-to-end run (~1–2 min)
- File header includes a one-paragraph explanation: "This table is the source of truth for what AID skills bracket with `▶/✓` lines per FR1 AC2 (work-003-traceability). The hint expansion fires when a SKILL's body calls `read-hint <class-name>` in a bracket-pair line. Sub-second tool calls are NOT in this table by design."
- Add to the existing `canonical/templates/` flat-rendering set (will ship to all 3 install trees automatically via the `render_templates.py` recursive rglob).

**Acceptance Criteria:**
- [ ] Created `canonical/skills/rough-time-hints.md` containing the markdown table.
- [ ] Required operation classes (12+ rows) all present.
- [ ] File header explains the table's role and the sub-second cutoff convention.
- [ ] All §6 quality gates pass

---

## §6 Quality Gates (this task type)

- [ ] **§6.1 — Line endings preserved.** New file written with LF (matching canonical/templates/ convention).
- [ ] **§6.2 — Generator passes.** `python run_generator.py` runs clean; new canonical asset ships to all 3 install trees per `/aid-generate`.
- [ ] **§6.3 — Cite-able.** Each row in the table can be cited by line number from a SKILL body's AC2 bracket-pair line.
