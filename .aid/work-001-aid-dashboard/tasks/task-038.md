# task-038: /aid-interview PF-1 identity header — Name/Description block in REQUIREMENTS.md (scaffold + Description-from-Objective compose)

**Type:** IMPLEMENT

**Source:** feature-009-producer-state-emission → delivery-006

**Depends on:** —

**Scope:**
- Make `/aid-interview` the producer of the PF-1 typed identity header in `REQUIREMENTS.md`: a `- **Name:**` + `- **Description:**` block placed **immediately after the `# Requirements` H1 and before `## Change Log`** (so it is the first content block, unambiguous to parse).
- `canonical/skills/aid-interview/references/state-first-run.md` (§1b / §1b-ii scaffold region): when ensuring/creating `REQUIREMENTS.md` from the template, scaffold the header block seeded `*(pending)*` (`- **Name:** *(pending)*` / `- **Description:** *(pending)*`) between `# Requirements` and `## Change Log`, alongside the existing `## Pipeline Status` seeding.
- `canonical/skills/aid-interview/references/state-completion.md` (the COMPLETION checkpoint that already surfaces `**Objective:** [1-2 sentences from §1]`): add a step that (a) sets `- **Name:**` to a short Title-Case human work name (no trailing period), (b) **composes a one-sentence Description from `## 1. Objective`** (a summary of the Objective body, NOT the Objective verbatim and NOT separately authored free-form), (c) **presents the composed Description to the user for confirmation** at COMPLETION, and (d) writes the confirmed Name + Description into the header block, replacing the `*(pending)*` seeds.
- `canonical/templates/requirements/requirements-template.md` (the `## Template` fenced block) and `canonical/templates/requirements.md`: add the `- **Name:**` / `- **Description:**` block between `# Requirements` and `## Change Log` so new works are born with the header (placeholder `*(pending)*` in the template body).
- Edits are **ASCII-only**, **behavior-preserving / additive** (C4/C5 — only adds emitted content; no phase/gate/output/decision change). This task edits `canonical/skills/**` only; the dogfood render into `.claude/skills/**` is task-043 (do NOT edit `.claude/skills/**` here).

**Acceptance Criteria:**
- [ ] `state-first-run.md` scaffolds the `- **Name:** *(pending)*` / `- **Description:** *(pending)*` block between `# Requirements` and `## Change Log` whenever `REQUIREMENTS.md` is created/ensured.
- [ ] `state-completion.md` instructs the agent to compose the one-sentence Description **from `## 1. Objective`**, present it for user confirmation, set a Title-Case Name, and write both into the header (replacing the `*(pending)*` seeds) — documented so the field matches the reader parse `^\s*-\s*\*\*Description:\*\*\s*(.+)`.
- [ ] `requirements-template.md` and `requirements.md` carry the identity-header block in the correct position (after H1, before `## Change Log`); a fresh `REQUIREMENTS.md` rendered from the template parses under `parse_requirements_md` for both Name and Description (PF-1 / T-1).
- [ ] All touched canonical files are ASCII-only (no non-ASCII bytes); the edits add emitted content only and change no `/aid-interview` phase, gate, advance, or decision (C4/C5).
- [ ] All §6 quality gates pass; the canonical edit is left to be dogfood-rendered by task-043 (this task does not run `run_generator.py` and does not modify `.claude/skills/**`).
