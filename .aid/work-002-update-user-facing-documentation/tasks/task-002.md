# task-002: README + docs/ — adopter documentation

**Type:** DOCUMENT

**Source:** work-002-update-user-facing-documentation → delivery-001

**Depends on:** task-001

**Scope:**
- Rewrite root `README.md` and `docs/glossary.md`, `docs/faq.md` per the information architecture and corrected fact-set from task-001.
- Audience: the **adopter** — understand the project at a glance, install AID into their own repo, and use it; include a basic how-it-works overview.
- Write the `examples/README.md` landing/index page that links the three rebuilt examples (navigational, per the IA).
- Remove the obsolete example directories identified by task-001 (`examples/desktop-app`, `examples/brownfield-enterprise`, `examples/data-pipeline`) so no stale example set survives alongside the rebuilt ones.
- Tone: **brief, direct, clear.** Install instructions + usage instructions + overview. No deep rationale (that belongs in the methodology blog).

**Acceptance Criteria:**
- [ ] `README.md`, `docs/glossary.md`, `docs/faq.md`, and `examples/README.md` are accurate against the corrected fact-set (lite path, current pipeline shape, five profiles incl. Copilot CLI + Antigravity). (SPEC AC: reconciled & accurate.)
- [ ] README is brief, direct, and clear, and gives install + usage instructions plus a how-it-works overview an adopter can grasp at a glance. (SPEC AC: README + docs.)
- [ ] Navigation follows the task-001 IA (README → docs → methodology → examples). (SPEC AC: information architecture.)
- [ ] The obsolete example directories (`desktop-app`, `brownfield-enterprise`, `data-pipeline`) are removed; only the three rebuilt examples remain under `examples/`. (SPEC AC: examples migration.)
- [ ] No methodology or behavior changes. (SPEC AC: docs-only.)
- [ ] All quality gates pass (see SPEC § Quality Gates).
