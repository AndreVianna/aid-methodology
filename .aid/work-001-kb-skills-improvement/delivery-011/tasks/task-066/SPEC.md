# task-066: Concept-first content components — glossary / ADR / capability (Change 2)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-066/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-011

**Depends on:** task-065

**Scope:**
- Implement feature-015 **Change 2 (FR-46)** — add the three concept-first content components so a
  newcomer never has to open a `.md`. Edit **canonical** sources only (regen is task-070).
- **Glossary / definition component** — renders `domain-glossary.md` terms as friendly
  definitions/pills/cards (the project's vocabulary, explained).
- **Decision / ADR card** — renders each `decisions.md` ADR (context -> decision -> rationale ->
  consequence) as a newcomer-readable card (the *why* behind the project).
- **Capability entry** — renders `capability-inventory.md` per capability (what the project can do).
- Add the component **styles** to `templates/knowledge-summary/component-css.css` (these are
  **inner-content** components — the shell/chrome is untouched, §5b).
- Wire the **`kb-category` -> component mapping** from the task-064 manifest into
  `templates/knowledge-summary/section-templates/*` and the generation flow in
  `references/state-generate.md`, so the Concept Spine, `decisions.md`, and the capability
  inventory are rendered as **content, not links**. For any resolved doc with no bespoke
  component, the **generic table/card/prose** rendering covers it (completeness = coverage, §0).
- `templates/knowledge-summary/prompt.md` — instruct concept-first rendering (render the term /
  ADR / capability as content; do not emit bare links to the source `.md`).

**Acceptance Criteria:**
- [ ] `domain-glossary.md` terms render as a **first-class glossary/definition component**
  (definitions/pills/cards), not as links. *(FR-46)*
- [ ] Each `decisions.md` ADR renders as a **decision/ADR card** (context -> decision -> rationale
  -> consequence), not as a link. *(FR-46)*
- [ ] `capability-inventory.md` renders as **capability entries**, not as links. *(FR-46)*
- [ ] Component styles are added to `component-css.css`; the mapping from `kb-category` to
  component is wired in the section templates + `state-generate.md`; a resolved doc with no bespoke
  component falls back to generic table/card/prose (no doc is dropped). *(FR-46, §0 completeness)*
- [ ] `prompt.md` instructs concept-first **rendered** content (no bare links to source `.md`).
  *(FR-46)*
- [ ] Components are **inner-content only** — the outer shell/chrome is untouched (§5b); the page
  stays single self-contained with no CDN/split asset/framework fetch (C2/C3); all CSS is inlined.
  Edits are in `canonical/...` only.
- [ ] All section-6 quality gates pass.
