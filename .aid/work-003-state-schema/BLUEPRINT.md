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
  **canonical** STATE templates.
- Both dashboard reader twins (`dashboard/reader/*.py` + `dashboard/server/reader.mjs`) read
  frontmatter-first with legacy-prose fallback, honoring the current dual `State|Status` section
  names and the flat/Lite layout; reader + twin-parity + fixtures updated.
- The STATE writers (`canonical/aid/scripts/**/writeback-state.sh` + hand-authoring skills)
  emit/update frontmatter atomically without corrupting the markdown body.
- Migration of every on-disk STATE.md file; re-vendor + `run_generator.py` propagation + CLI rebuild.

**Out of scope:** the `§6`-dangling-ref template-ism, KB closure-hygiene, and `aid --version`
(tracked separately as the hygiene batch); restructuring the human-narrative sections themselves.

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

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Reconciled from a retired lite-path scaffold to the flattened Lite-work conventions after the
`70895e8b` master merge (which deleted the old lite path and rewrote the reader twins). The
task plan was re-validated against the rewritten reader: the bug still reproduces, and the
frontmatter + `SourceMode` approach still fits. Detailed design belongs in the task DETAIL.md files.
