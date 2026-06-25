# task-070: Regen (full run_generator.py) + .claude DBI sync + SKILL/README docs

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-070/STATE.md.

**Type:** DOCUMENT

**Source:** work-001-kb-skills-improvement -> delivery-011

**Depends on:** task-065, task-066, task-067, task-068, task-069

**Scope:**
- Land the D-011 canonical edits into the rendered host trees and finalize the user-facing docs.
  This is the **regen + sync + doc** step, run after all D-011 IMPLEMENT/TEST tasks are green.
- **Full regen:** run the **full `run_generator.py`** (at
  `.claude/skills/generate-profile/scripts/run_generator.py`) — NOT per-script renderers — so all
  emission manifests update and CI render-drift stays green (per the render-drift lesson).
- **`.claude` dogfood sync (DBI):** confirm the rendered `.claude/skills/aid-summarize/...` and
  `.claude/.../knowledge-summary/...` are byte-identical to the canonical render (dogfood
  byte-identity), and the live AID KB's own summary path is consistent.
- **Docs:** update `SKILL.md` user-facing prose (if not fully covered by task-065), the
  aid-summarize `README`/reference docs to describe the doc-set/domain-driven, newcomer-audience,
  concept-first summary, and append a `.aid/knowledge/release-tracking.md` entry
  (`[CHANGE]`, newest-first) for the D-011 summary realignment; regenerate
  `.aid/knowledge/INDEX.md` via `canonical/scripts/kb/build-kb-index.sh` if any KB doc changed.
- If adding/removing a user-facing skill count is implicated (it is not expected here), defer the
  count reconciliation to `/aid-housekeep` per the count-drift lesson — do not inline it.

**Acceptance Criteria:**
- [ ] The **full `run_generator.py`** has been run; the rendered `.claude/` aid-summarize +
  knowledge-summary trees are **byte-identical** to the canonical render (DBI green); CI
  render-drift would pass (no stale emission manifest). *(quality gates)*
- [ ] `SKILL.md` + the aid-summarize reference/README docs describe the **doc-set/domain-driven,
  non-technical-newcomer, concept-first** summary (no stale profile-as-project-type or phantom-doc
  language survives). *(FR-45–FR-49)*
- [ ] A `release-tracking.md` `[CHANGE]` entry is appended (newest-first) for the D-011
  realignment; `INDEX.md` is regenerated via the canonical `build-kb-index.sh` if any KB doc
  changed. *(KB hygiene)*
- [ ] Guardrails C1/C2/C3/C5/C6 + §5b remain intact after regen; no `.claude/` file was edited
  directly (all changes flow from `canonical/` through `run_generator.py`).
- [ ] All section-6 quality gates pass.
