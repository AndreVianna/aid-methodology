# User-Facing Documentation — Refactor

- **Work:** work-002-update-user-facing-documentation
- **Created:** 2026-06-03
- **Source:** /aid-interview lite path — LITE-REFACTOR
- **Status:** Ready

## Goal

The user-facing documentation has drifted from the current methodology. Recent
changes — the addition of **AID lite**, re-placement of some skills in the pipeline,
a changed **pipeline shape**, and two new profiles (**GitHub Copilot CLI** and
**Antigravity**) — are not reflected, and there may be further undocumented drift.
This work reviews and rewrites all user-facing documentation (text, diagrams, images)
so it is accurate against the current methodology, restructures it around two clear
audiences (the adopter and the learner), and rebuilds the worked examples from scratch.
**No methodology or behavior changes are made — documentation only.**

## Context

**Scope:** All user-facing documentation in the repository:

- `README.md` (root)
- `methodology/aid-methodology.md` + its images (`methodology/images/2-comparison.png`, `methodology/images/3-ironman.png`)
- `docs/` — `glossary.md`, `faq.md`
- `examples/` — current sets (`desktop-app`, `brownfield-enterprise`, `data-pipeline`) to be **redone from scratch**
- All embedded text, diagrams, and images are in scope for review/regeneration.
- A full **reorganization** of this documentation is acceptable.

**Out of scope:** Any change to the methodology itself — skills, agents, scripts,
profiles, canonical sources, or behavior. This work touches user-facing docs only.

**Before (current problems):** The documentation describes an older methodology.
Known drift:

- **AID lite** (the lite path) is not documented.
- Some **skills were re-placed** in the pipeline; docs show the old placement.
- The **pipeline shape itself changed**; docs/diagrams show the old shape.
- **Profiles** now include **GitHub Copilot CLI** and **Antigravity** (five host-tool
  trees total); docs likely list only Claude Code / Codex / Cursor.
- The `examples/` reference outdated structure and workflow.
- There may be **additional undocumented changes** not yet enumerated — a reconciliation
  pass against the current source of truth is required to find them.

**After (desired state), organized by audience:**

- **`methodology/` (the learner / blog audience):** a **blog-post-style** narrative for
  readers who want to understand the *philosophy* and *technical aspects* of the
  methodology — in-depth rationale, pros and cons, and comparisons with other
  methodologies, going **deep into each skill and agent**. (Detailed content may be
  refined collaboratively, including during execution.)
- **`README.md` + `docs/` (the adopter audience):** lets an adopter understand the
  project at a glance, **install** it into their own repo, and **use** it — plus a basic
  overview of how the method works.
- **`examples/` (intersection of both audiences):** **3 worked examples** in **tutorial
  style**, reflecting realistic problems:
  - 1 **greenfield** project
  - 1 **brownfield** project on the **full path**
  - 1 **brownfield** project on the **lite path**
- **Information architecture:** a clear entry point and reading path for adopters.

**Tone / format requirements (per audience):**

- **README:** brief, direct, clear — at-a-glance understanding and "apply to your own repo."
- **Methodology (blog):** deep, detailed, with rationale, pros and cons, and per-skill /
  per-agent depth for the learner.
- **Examples:** tutorial style — step-by-step, explaining the key aspects of each step.

**Sources of truth (for execution):** the Knowledge Base (`.aid/knowledge/`, regenerated
2026-06-03), the knowledge-summary (`.aid/knowledge/knowledge-summary.html`), and the
current repository files. The methodology author (the user) is available for clarifying
and enrichment questions at any time, including during execution.

KB references: `architecture.md` (canonical→render→install pipeline, five host-tool
trees, 6-phase pipeline, lite path, agent-tier model), `domain-glossary.md`,
`project-structure.md`, `coding-standards.md`.

## Acceptance Criteria

- [ ] **Reconciled & accurate:** all user-facing docs match the current methodology — no
      factually stale claims. Lite path documented; corrected pipeline shape & skill
      placement; all **five** profiles listed (incl. GitHub Copilot CLI + Antigravity).
- [ ] **Drift audit performed:** the docs were diffed against the KB / knowledge-summary,
      and drift items *beyond* the known list are fixed or explicitly logged.
- [ ] **Methodology (blog):** `methodology/aid-methodology.md` reads as a deep, detailed
      blog-post narrative — philosophy, technical rationale, pros and cons, comparison
      with other methodologies, and per-skill / per-agent depth. Diagrams/images
      regenerated to match the current pipeline.
- [ ] **README + docs (adopter):** brief, direct, and clear; gives install instructions,
      usage instructions, and a basic how-it-works overview at a glance.
- [ ] **Examples rebuilt from scratch:** 3 tutorial-style worked examples — 1 greenfield,
      1 brownfield full-path, 1 brownfield lite-path — each step-by-step and explaining
      the key aspects of each step, reflecting a realistic problem.
- [ ] **Information architecture:** a clear entry point and reading path for adopters
      across README → docs → methodology → examples.
- [ ] **Examples migration:** the obsolete example directories (`desktop-app`,
      `brownfield-enterprise`, `data-pipeline`) are removed once replaced, leaving only
      the three rebuilt examples — no stale example set survives.
- [ ] **Docs-only:** no methodology, agent, skill, script, profile, or behavior changes.
- [ ] All quality gates pass (see § Quality Gates).

## Quality Gates

The quality gates for this documentation work (referenced by every task's final AC):

1. **Renders cleanly** — Markdown renders without errors; no broken formatting.
2. **Links & images resolve** — all internal links, cross-doc references, and image
   paths resolve; no dangling references.
3. **No behavior regression** — the existing repository test suite remains green
   (documentation-only change; absorbs "all existing tests pass").
4. **KB-accurate** — content matches the task-001 corrected fact-set; no stale claims.
5. **Docs-only** — no changes outside user-facing documentation (no methodology, agent,
   skill, script, profile, or behavior changes).

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | RESEARCH | Drift audit + information-architecture design |
| task-002 | DOCUMENT | README + docs/ — adopter documentation |
| task-003 | DOCUMENT | methodology/ — the blog narrative |
| task-004 | DOCUMENT | examples/ — greenfield worked example |
| task-005 | DOCUMENT | examples/ — brownfield full-path worked example |
| task-006 | DOCUMENT | examples/ — brownfield lite-path worked example |

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
| task-003 | task-001 |
| task-004 | task-001 |
| task-005 | task-001 |
| task-006 | task-001 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002, task-003, task-004, task-005, task-006 |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-06-03 | Initial lite-path SPEC created | /aid-interview LITE-REFACTOR |
| 2026-06-03 | Tasks + Execution Graph filled (6 tasks) | /aid-interview TASK-BREAKDOWN |
