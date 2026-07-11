# Delivery BLUEPRINT -- delivery-001: Structured STATE Frontmatter

<!-- DELIVERY-LEVEL BLUEPRINT.md — the IMMUTABLE DEFINITION for delivery-001 of this flattened
     single-delivery work. The delivery gate reads its criteria from `## Gate Criteria` below
     (NOT from STATE.md). Task state lives in STATE.md `### Tasks lifecycle`. -->

> **Delivery:** delivery-001
> **Work:** work-003-state-schema
> **Created:** 2026-07-09

---

## Objective

AID's STATE files store machine-parsed values (approval, grades, status/lifecycle enums, counts,
output paths, timestamps) inside free-form markdown, read by regex across two dashboard reader
twins. Because the same value can be a blockquote line, a table row, or a bold label, slight
formatting variance silently misparses — the trigger being an **approved** Knowledge Base
rendering as "Building" with a dead `kb.html`, because approval was recorded as a table row
rather than the section bold line the reader expects. This delivery moves the machine-parsed
values into a defined **YAML-frontmatter schema** per STATE file, read deterministically
(frontmatter-first, legacy-prose fallback), keeping the human narrative as markdown body —
eliminating the regex-fragility bug class without losing the readable ledger.

## Scope

- A structured YAML-frontmatter schema for the machine-parsed STATE fields, embodied in the 4
  **canonical** STATE templates. The schema also **captures information that is currently missing
  or only inferred**: the pipeline type (`pipeline.path` lite|full + `pipeline.initiator`, the
  starting skill — which fixes the dashboard's "Lite path: Lite" render), plus **genuinely-missing**
  fields (`started`, work-level `user_approved`, KB `kb_status`/`kb_grade`/`last_kb_review` —
  authored but never parsed) and **de-fragilized relocations** of already-parsed-but-brittle values
  (`minimum_grade`, KB `summary_approved`/`last_summary`).
- Both dashboard reader twins (`dashboard/reader/*.py` + `dashboard/server/reader.mjs`) read
  frontmatter-first with legacy-prose fallback, honoring the current dual `State|Status` section
  names and the flat/Lite layout; reader + twin-parity + fixtures updated.
- The STATE writers (`canonical/aid/scripts/**/writeback-state.sh` + hand-authoring skills)
  emit/update frontmatter atomically without corrupting the markdown body.
- Migration of every on-disk STATE.md file; re-vendor + `run_generator.py` propagation + CLI rebuild.

**Also folded into this delivery** (independent maintenance fixes, tasks 006–010):
- Normalize the dangling `§6`/`section-6` quality-gate reference across the canonical templates (task-006).
- Validate + root-cause KB concept-closure hygiene — no security-theater exclusion-padding (task-007).
- Add a `--version` flag to the `aid` CLI, aliasing the existing `aid version` (task-008).
- Make task-state updates emphatic + unmissable in the execution flow so the dashboard shows live progress (task-009, user-reported gap).
- Reconcile the phase model to the real pipeline (Discover→Describe→Define→…→Execute) end-to-end + render the Lite path distinctly from the full path (task-010, user-reported gap).

**Out of scope:** restructuring the human-narrative sections themselves; the version bump to
v2.1.0 (landed on master via PR #139, inherited here by pull — not a task).

## Gate Criteria

- [ ] Machine-parsed fields (approval, grades, status/lifecycle enums, counts, output path, timestamps) are read from structured YAML frontmatter, not scraped from prose.
- [ ] The dashboard reads this repo's approved KB as **approved** (KB card opens `kb.html`), driven by the new frontmatter format — not the main-checkout stopgap.
- [ ] Both reader twins (Python + Node) parse the new frontmatter **identically** (twin-parity test passes); `SourceMode` is extended onto the KB path (it is per-work only today).
- [ ] The reader honors both `State|Status` section spellings and the flat/Lite layout; any new reader module is registered in `dashboard/MANIFEST` (or it silently won't vendor).
- [ ] Writers update frontmatter fields **without corrupting** the markdown narrative body.
- [ ] **No status regression during rollout** — the tolerant reader parses old-format files AND migration converts the in-repo files.
- [ ] Every on-disk STATE file (live-enumerated via `find .aid -name STATE.md`) migrated and read correctly; narrative sections remain human-readable markdown.
- [ ] Reader re-vendored into `packages/pypi` + `packages/npm`; canonical template/writer/skill changes rendered to all profiles + dogfood via `run_generator.py`; `test-dogfood-byte-identity.sh` passes.
- [ ] Reader fixtures (`pt1h-kb-approved`, `test_task064/066`) migrated in the same change; new + existing tests pass; git-fed fields routed through v2.1.0's hardened helpers.
- [ ] The `§6`/`section-6` quality-gate references are validated + classified; genuinely-dangling standing lines are normalized to a non-dangling form (or, if none are genuinely dangling, closed Not Applicable with evidence); legitimate references left untouched; regenerated; `test-dogfood-byte-identity.sh` passes (task-006).
- [ ] KB concept-closure is validated at HEAD and either root-caused or documented Not Applicable with evidence — no blind `term_exclusions` padding (task-007).
- [ ] `aid --version` prints the CLI version on both `bin/aid` and `bin/aid.ps1`, aliasing `aid version`, and is documented in `aid -h` (task-008).
- [ ] The frontmatter schema ADDS the genuinely-missing fields (`pipeline{path,initiator}`, `started`, work-level `user_approved`, KB `kb_status`/`kb_grade`/`last_kb_review`) AND relocates the already-parsed-but-brittle ones (`minimum_grade`, KB `summary_approved`/`last_summary`) into frontmatter without regressing existing behavior — authored by the pipeline-starting skills + writers, read by both reader twins (task-001/002/004/005).
- [ ] The dashboard renders lite works faithfully: the real pipeline **kind** from `pipeline.initiator` (e.g. "Lite path: Refactor → 8 Tasks") — "Lite path: Lite" no longer appears, `work_path` comes from `pipeline.path` (not layout inference); AND the detail-view stage rail shows a compact **Defining → Executing → Done** rail for lite works instead of the full 7-phase stepper (full works unchanged) (task-002).
- [ ] The **canonical** sources (aid-execute skill flow, the canonical task templates so EVERY created task inherits it, and the CLAUDE.md/AGENTS.md source) **emphatically and unmissably** mandate writing the task state at each transition (`In Progress` at EXECUTE-start, `In Review` at execute-complete, terminal at end) — binding whoever executes (main orchestrator OR sub-agent, no bypass), for both full and flattened layouts + single/pool dispatch — so the dashboard reflects live progress instead of a task stuck at `Pending`; regression-tested for the flattened `### Tasks lifecycle` path through both reader twins (task-009).
- [ ] The dashboard + STATE `Phase` enum reflect the **real** pipeline (`Discover → Describe → Define → Specify → Plan → Detail → Execute`, Deploy as an optional post-Execute indicator, the dead `Monitor` value removed) — encoded consistently across template + writer-validation + skill write-sites + both reader twins + the dashboard; the retired `Interview` label is migrated (with a back-compat read alias so task-005-migrated files still parse); and the **Lite/shortcut path renders a DISTINCT display** from the full stepper, driven by the correct model signal (task-010).
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | DESIGN | Define the STATE YAML-frontmatter schema + update the 4 templates |
| task-002 | REFACTOR | Dual-format frontmatter read in both reader twins + tests |
| task-003 | CONFIGURE | Ship the new reader to the installed CLI (vendor + resync + pipx) |
| task-004 | REFACTOR | Emit/update frontmatter in the STATE writers |
| task-005 | MIGRATE | Migrate on-disk STATE files + verify the real bug is fixed |
| task-006 | REFACTOR | Normalize genuinely-dangling quality-gate references in AID templates |
| task-007 | REFACTOR | Validate + remediate KB concept-closure hygiene |
| task-008 | IMPLEMENT | Add a `--version` flag to the aid CLI |
| task-009 | REFACTOR | Make task-state updates emphatic + unmissable in the execution flow |
| task-010 | REFACTOR | Reconcile the phase model to the real pipeline (faithful) + distinct Lite display |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Reconciled from a retired lite-path scaffold to the flattened Lite-work conventions after the
`70895e8b` master merge (which deleted the old lite path and rewrote the reader twins). The
task plan was re-validated against the rewritten reader: the bug still reproduces, and the
frontmatter + `SourceMode` approach still fits. Detailed design belongs in the task DETAIL.md files.
