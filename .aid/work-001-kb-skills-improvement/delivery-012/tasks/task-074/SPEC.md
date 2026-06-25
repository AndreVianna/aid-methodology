# task-074: §7 visual-fidelity gate — validate-visuals.mjs (Playwright) + state-validate rework + no-engine assertion

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-074/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-012

**Depends on:** task-072, task-073

**Scope:**
- Implement the **§7 visual-fidelity gate** (FR-51) — the authored-visual replacement for
  Mermaid's free layout guarantee. Edit **canonical** sources only (regen is task-076).
- **Replace `scripts/summarize/validate-diagrams.mjs` with a new
  `scripts/summarize/validate-visuals.mjs`.** This is **not a rename**: the old validator renders
  via **JSDOM** (non-browser DOM); the new one **Playwright-renders** every authored visual
  (using the task-073 provisioning) and asserts, per visual: **text is readable** (legible size,
  not clipped), **minimal/zero element overlap**, and a **correct basic layout** (non-trivial —
  not collapsed/empty). The old Mermaid-D2 syntax/render check is **removed** (moot once the engine
  is gone). A visual that fails the gate is a **generation defect, fixed before DONE**.
- Document the **explicit visual-inspection fallback** (when Playwright is unavailable) per §7 and
  the global rule that any review of rendered web output uses Playwright visual validation —
  reading HTML/CSS source is not sufficient.
- **`references/state-validate.md`** — rework the VALIDATE state: the visual-fidelity gate
  **replaces** the diagram-render check; document the per-visual assertions + the fallback.
- **`scripts/summarize/validate-html-output.sh`** — keep the self-containment + a11y checks and
  **add a no-Mermaid-engine assertion** (the output contains no Mermaid engine / init / external
  fetch). ASCII-only + WinPS-5.1-safe is moot for `.sh` but keep it ASCII-only.
- **`SKILL.md`** — update the VALIDATE-state prose to the visual-fidelity gate.

**Acceptance Criteria:**
- [ ] `validate-diagrams.mjs` is replaced by a new **`validate-visuals.mjs`** that
  **Playwright-renders** every authored visual and asserts **readable text + minimal/zero overlap +
  correct basic layout** per visual; the old Mermaid-D2 check is gone. *(FR-51, §7)*
- [ ] A visual failing the gate is treated as a **generation defect that blocks DONE** (same rigor
  as the old "no broken diagram" guarantee); the **visual-inspection fallback** is documented.
  *(FR-51, §7)*
- [ ] `state-validate.md` reworks the VALIDATE state so the visual-fidelity gate **replaces** the
  diagram-render check; `SKILL.md` VALIDATE prose matches. *(FR-51)*
- [ ] `validate-html-output.sh` keeps the self-containment + a11y checks and **adds a
  no-Mermaid-engine assertion** (no engine / init / external fetch in the output). *(C2/C3, FR-51)*
- [ ] Guardrails C1/C2/C3/C5/C6 + §5b intact; edits are in `canonical/...` only; the validator
  needs no external fetch (renders the local self-contained file). *(guardrails)*
- [ ] All section-6 quality gates pass.
