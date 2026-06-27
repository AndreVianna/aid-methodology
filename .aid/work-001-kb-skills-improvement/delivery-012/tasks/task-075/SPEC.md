# task-075: Visual-fidelity fixtures + payload-size regression + guardrail re-checks

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-075/STATE.md.

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-012

**Depends on:** task-071, task-072, task-074

**Scope:**
- Add the test coverage for the D-012 engineering changes (Changes 6-7 + §7 gate) and re-assert
  the §5 guardrails after the engine re-architecture. TEST only — no skill behavior changes here.
- **§7 visual-fidelity fixtures (Playwright):** fixtures with (a) a **good** authored visual that
  **passes** (readable text, no overlap, non-trivial layout) and (b) **defect** visuals that the
  gate must **fail** (clipped/illegible text, overlapping elements, collapsed/empty layout) — so
  the gate is proven to catch the failure class Mermaid used to prevent. Uses the task-073
  Playwright provisioning.
- **Determinism (Change 6):** assert the same doc-set input yields the **same structural output**
  from the deterministic assembler (reproducible/auditable); cover the `.sh` path (and, where the
  lane runs it, the `.ps1` twin parity).
- **Payload-size regression (Change 7):** assert the generated `kb.html` is **dramatically
  smaller** (target: tens of KB, well under the old ~3.4MB) and contains **no Mermaid engine / init
  / external fetch** (the no-engine assertion from task-074 holds end-to-end).
- **Guardrail re-checks (C1/C2/C3/C5/C6 + §5b):** C1 path, C2/C3 single self-contained file (no
  CDN / split asset / framework fetch — dropping Mermaid introduced **no** external fetch), C5
  approval signal, C6 completeness/`kb_baseline` shapes, §5b page-shell alignment preserved.
- Follow the split-big-TEST-tasks lesson: keep the suites small and per-concern (fidelity fixtures
  vs determinism vs payload vs guardrails); if any single suite balloons, split into per-suite
  sub-units. Tests target the **canonical** summarize suites; rendering/DBI is task-076.

**Acceptance Criteria:**
- [ ] Playwright fidelity fixtures prove the gate **passes** a good authored visual and **fails**
  clipped-text / overlapping-element / collapsed-layout defects. *(FR-51, §7)*
- [ ] A determinism test asserts the same doc-set input yields the **same structural output** from
  the deterministic assembler. *(FR-50)*
- [ ] A payload-size regression asserts `kb.html` is **tens of KB** (well under ~3.4MB) with **no
  Mermaid engine / init / external fetch**. *(FR-51)*
- [ ] Guardrail re-checks confirm **C1/C2/C3/C5/C6 + §5b** hold after the engine re-architecture.
  *(guardrails)*
- [ ] All section-6 quality gates pass.
