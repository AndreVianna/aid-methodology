# task-071: Data-driven deterministic assembly (assemble.sh / assemble-3part.sh + WinPS twin) — Change 6

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-071/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-012

**Depends on:** delivery-011 (the correctness core — doc-set/domain section manifest + content
components the deterministic assembler now assembles)

**Scope:**
- Implement feature-015 **Change 6 (FR-50)** — make summary generation **data-driven and
  deterministic** from the resolved doc-set. Edit **canonical** sources only (regen is task-076).
- **`scripts/summarize/assemble.sh` + `scripts/summarize/assemble-3part.sh`** — assemble the
  single-file output **mechanically** from the resolved doc-set manifest + frontmatter + component
  library: section ordering, shell, component selection, and inlining are deterministic
  (same input -> same structural output, auditable). The LLM's role is **narrowed to per-component
  content authoring** (judgment), not hand-writing the page HTML.
- **`scripts/summarize/assemble-3part.ps1` (WinPS twin)** — apply the **same** deterministic
  assembly to the PowerShell twin. The sh/ps1 parity cornerstone requires both twins move
  together; the `.ps1` stays **ASCII-only + WinPS-5.1-safe** (no 3-arg `Join-Path`, `-Encoding
  utf8NoBOM` where writing, TLS1.2, no non-ASCII). (The `-Mermaid` embed param is **dropped** in
  task-072 — this task keeps it but routes assembly deterministically; ordering with task-072 is
  via the `Depends on` chain.)
- **`references/state-generate.md`** — rework the GENERATE flow to the data-driven path:
  resolve the doc-set manifest, author per-component content, then **assemble deterministically**;
  document the reproducibility/auditability contract (same input -> same structural output).
- Mechanical work lives in the scripts; irreducible judgment (per-component content authoring,
  tone) stays in the state prose / prompt.

**Acceptance Criteria:**
- [ ] Generation is **data-driven and deterministic** from the resolved doc-set: assembly, section
  ordering, shell, and inlining are mechanical; the same input yields the same structural output
  (reproducible + auditable). *(FR-50)*
- [ ] The LLM's role is **narrowed to per-component content authoring** — it no longer hand-writes
  the page HTML; `state-generate.md` documents the narrowed role + the determinism contract.
  *(FR-50)*
- [ ] `assemble.sh`, `assemble-3part.sh`, **and** the WinPS twin `assemble-3part.ps1` are updated
  **together** (sh/ps1 parity); `assemble-3part.ps1` is ASCII-only + WinPS-5.1-safe. *(FR-50,
  parity cornerstone)*
- [ ] The output stays a **single self-contained file** (C2/C3 — no CDN/split asset/framework
  fetch) at path C1; C5/C6 + §5b unaffected. Edits are in `canonical/...` only.
- [ ] All section-6 quality gates pass.
