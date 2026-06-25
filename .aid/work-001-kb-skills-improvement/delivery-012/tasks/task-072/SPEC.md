# task-072: Pre-render visuals to inline SVG; drop the ~3MB Mermaid engine (Change 7)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-072/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-012

**Depends on:** task-071

**Scope:**
- Implement feature-015 **Change 7 (FR-51)** — pre-render every visual to inline SVG / HTML+CSS at
  build time and **remove the ~3MB runtime Mermaid engine**. Edit **canonical** sources only
  (regen is task-076). The §7 visual-fidelity gate that this change makes necessary is the **next**
  task (task-074); this task does the removal + pre-render wiring.
- **Pre-render path:** wire `references/state-generate.md` (and the task-071 deterministic
  assembler) to emit visuals as **inline SVG / HTML+CSS** at build time — static visuals need no
  runtime engine. Inline only (no CDN, no fetch — C2/C3).
- **Remove the Mermaid engine:**
  - `scripts/summarize/fetch-mermaid.sh` — **remove**.
  - `templates/knowledge-summary/mermaid-init.js` — **remove**.
  - `templates/knowledge-summary/html-skeleton.html` — **remove** the Mermaid loading/embedding
    (no engine `<script>`, no init hook).
  - `scripts/summarize/assemble-3part.ps1` — **drop the `-Mermaid` embed path** (the WinPS twin
    embeds the engine via its mandatory `-Mermaid` param); update the param/usage so the twin no
    longer embeds an engine. sh/ps1 parity cornerstone: the `.sh`/`.ps1` change together; `.ps1`
    stays ASCII-only + WinPS-5.1-safe.
  - `templates/knowledge-summary/mermaid-examples.md` — **retire or recast** as an
    **authored-visual catalog** (SVG / HTML+CSS patterns), not Mermaid source.
- The page remains **single-file self-contained** (C2/C3): inlined SVG, no engine, no external
  fetch; target payload drops from ~3.4MB to tens of KB.

**Acceptance Criteria:**
- [ ] Visuals are **pre-rendered to inline SVG / HTML+CSS at build time**; the page carries no
  runtime diagram-rendering engine. *(FR-51)*
- [ ] The **Mermaid engine is removed**: `fetch-mermaid.sh` and `mermaid-init.js` are gone, the
  `html-skeleton.html` Mermaid embed is gone, the `assemble-3part.ps1 -Mermaid` embed path is
  dropped, and `mermaid-examples.md` is retired/recast as an authored-visual catalog. A repo-wide
  grep for `mermaid` in `canonical/skills/aid-summarize` + `canonical/aid/.../knowledge-summary` +
  `canonical/aid/scripts/summarize` returns no live engine reference. *(FR-51)*
- [ ] The resulting `kb.html` is dramatically smaller (target: tens of KB rather than ~3.4MB) and
  stays **single self-contained** with **no external fetch** (C2/C3) at path C1. *(FR-51,
  guardrails)*
- [ ] `assemble-3part.ps1` change accompanies the `.sh`/template changes (sh/ps1 parity) and stays
  ASCII-only + WinPS-5.1-safe. Edits are in `canonical/...` only; C5/C6 + §5b unaffected.
- [ ] All section-6 quality gates pass.
