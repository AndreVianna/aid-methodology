# task-076: Regen + .claude DBI sync + SKILL/README docs + log the server-gzip fast-follow

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-076/STATE.md.

**Type:** DOCUMENT

**Source:** work-001-kb-skills-improvement -> delivery-012

**Depends on:** task-071, task-072, task-073, task-074, task-075

**Scope:**
- Land the D-012 canonical edits into the rendered host trees and finalize user-facing docs +
  the fast-follow log. Run after all D-012 IMPLEMENT/CONFIGURE/TEST tasks are green.
- **Full regen:** run the **full `run_generator.py`** (at
  `.claude/skills/generate-profile/scripts/run_generator.py`) — NOT per-script renderers — so all
  emission manifests update and CI render-drift stays green; confirm the **removed** Mermaid assets
  (`fetch-mermaid.sh`, `mermaid-init.js`) are gone from the rendered tree too (not just canonical).
- **`.claude` dogfood sync (DBI):** confirm the rendered `.claude/skills/aid-summarize/...` +
  `.claude/.../knowledge-summary/...` + `.claude/.../scripts/summarize/...` are byte-identical to
  the canonical render (DBI green), including the new `validate-visuals.mjs` and the dropped
  Mermaid files.
- **Docs:** update `SKILL.md` + the aid-summarize reference/README to describe the **data-driven
  deterministic** generation, the **inline-SVG / no-Mermaid-engine** output, and the **§7
  visual-fidelity gate**; append a `.aid/knowledge/release-tracking.md` entry (`[CHANGE]` +
  `[FIX]` for the silent-failure-class removal, newest-first); regenerate `.aid/knowledge/INDEX.md`
  via `canonical/scripts/kb/build-kb-index.sh` if any KB doc changed.
- **Log the fast-follow (OUT of this work):** record the **server-side gzip/cache of the dashboard
  leaf** (`dashboard/server/server.mjs` + `server.py` byte-parity twins) as an explicit
  fast-follow — the highest-ROI perf fix but a **different component** (the server, not the skill)
  — in the appropriate backlog/STATE note so it is not lost.

**Acceptance Criteria:**
- [ ] The **full `run_generator.py`** has been run; the rendered `.claude/` aid-summarize +
  knowledge-summary + summarize-scripts trees are **byte-identical** to the canonical render (DBI
  green), the new `validate-visuals.mjs` is present, and the dropped Mermaid assets are gone from
  the rendered tree; CI render-drift would pass. *(quality gates)*
- [ ] `SKILL.md` + the aid-summarize reference/README describe **data-driven deterministic
  generation**, the **inline-SVG / no-Mermaid-engine** output, and the **§7 visual-fidelity gate**;
  no stale Mermaid/runtime-engine language survives. *(FR-50, FR-51)*
- [ ] A `release-tracking.md` `[CHANGE]`/`[FIX]` entry is appended (newest-first); `INDEX.md` is
  regenerated via the canonical `build-kb-index.sh` if any KB doc changed. *(KB hygiene)*
- [ ] The **server-gzip/cache fast-follow** (OUT of this work — server, not skill) is **logged**
  explicitly so it is not lost. *(scope boundary)*
- [ ] Guardrails C1/C2/C3/C5/C6 + §5b remain intact after regen; no `.claude/` file was edited
  directly. *(guardrails)*
- [ ] All section-6 quality gates pass.
