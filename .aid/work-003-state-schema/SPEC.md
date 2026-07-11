# Structured STATE Frontmatter — Refactor

- **Name:** Structured STATE Frontmatter
- **Description:** Move machine-parsed STATE fields into a defined YAML-frontmatter schema read deterministically by AID skills and the dashboard, keeping the human narrative as markdown body
- **Work:** work-003-state-schema
- **Created:** 2026-07-09
- **Source:** /aid-describe lite path — LITE-REFACTOR
- **Status:** Ready

## Goal

AID's STATE files (work, delivery, task, and discovery) store machine-parsed values —
approval, grades, status/lifecycle enums, counts, output paths, timestamps — inside
free-form markdown, read by ~35 regex parsers across the Python and Node dashboard
reader twins. Because the same value can be written as a blockquote line, a table row,
or a bold label, slight formatting variance silently misparses — the trigger for this
work was an **approved** Knowledge Base rendering as "Building" in the dashboard with a
dead `kb.html` button, because the approval was recorded as a table row rather than the
bold line the reader expected. This refactor moves the machine-parsed values into a
**defined YAML-frontmatter schema** at the top of each STATE file, read deterministically
(no regex scraping), while keeping the human narrative (Review History, Q&A, Calibration
Log) as markdown body — eliminating the regex-fragility bug class without sacrificing the
human-readable ledger.

## Context

**Scope:**
- **Schema definition** — a structured YAML-frontmatter schema for machine-parsed state
  fields: approval, machine/human grades, status + lifecycle enums (closed sets), doc/task
  counts, output paths, timestamps. Narrative sections stay in the markdown body.
- **The 4 STATE templates (canonical)** — `canonical/aid/templates/work-state-template.md`,
  `delivery-state-template.md`, `task-state-template.md`, `discovery-state-template.md`
  (the SOURCE; the `.claude/aid/...` copies are generated output). Add the frontmatter
  block; move machine fields into it; keep narrative sections as body. Re-render via
  `run_generator.py` → all profiles + dogfood resync; `test-dogfood-byte-identity.sh` passes.
- **Both dashboard reader twins** — `dashboard/reader/*.py` (parsers.py, derivation.py,
  reader.py, models.py) and `dashboard/server/reader.mjs` (the reader's own source — NOT
  under canonical/ or profiles/): read machine fields from frontmatter; preserve byte-parity.
- **The writers (canonical)** — `canonical/aid/scripts/execute/writeback-state.sh`,
  `canonical/aid/scripts/summarize/writeback-state.sh`, and the hand-authoring skill refs
  under `canonical/skills/*/references/`: update/emit frontmatter atomically without
  clobbering the body. Re-render + resync as above.
- **Migration** — convert every on-disk STATE file (live-enumerated: `find .aid -name
  STATE.md`) to the new format; back-compat tolerant reader so pre-migration files still
  parse during rollout (adopter projects carry existing works).
- **Propagation** — reader → re-vendor into `packages/pypi` + `packages/npm` + `pipx
  install --force`; template/writer/skill changes → `run_generator.py` renders `canonical/`
  into all 5 `profiles/` + dogfood `.claude/` resync (byte-identity gate).

**Before:** machine-parsed values live in free-form markdown — sometimes a blockquote line,
sometimes a table row, sometimes a bold label — read by ~35 regex parsers across two reader
twins. Slight formatting variance silently misparses (the approved-KB-shows-"Building" bug).

**After:** those values live in a defined YAML-frontmatter block per STATE file, parsed
deterministically; narrative sections remain markdown body; writers update frontmatter
fields atomically without touching the body.

**KB references (via `.aid/knowledge/INDEX.md`):** `artifact-schemas.md` (STATE.md field
schemas — the artifact being restructured), `module-map.md` (dashboard reader twin
locations), `pipeline-contracts.md` (state writeback contract), `coding-standards.md`
(Python/Node twin byte-parity requirement), `test-landscape.md` (reader twin test suites).

## Acceptance Criteria

- [ ] Machine-parsed fields (approval, grades, status/lifecycle enums, counts, output path, timestamps) are read from structured YAML frontmatter, not scraped from prose.
- [ ] The dashboard reads this repo's approved KB as **approved** (KB card opens `kb.html`) — the real bug is fixed by the new format, not just the stopgap markdown edit.
- [ ] Both reader twins (Python + Node) parse the new frontmatter **identically** (twin-parity test passes).
- [ ] Writers (`writeback-state.sh` + skills) update frontmatter fields **without corrupting** the markdown narrative body.
- [ ] **No status regression during rollout** — the reader stays tolerant of old-format files AND migration converts the in-repo files (tolerant dual-format reader strategy).
- [ ] Every on-disk STATE file (live-enumerated via `find .aid -name STATE.md`) migrated and read correctly.
- [ ] Narrative sections (Review History, Q&A, Calibration Log) remain human-readable markdown.
- [ ] Propagation complete: reader re-vendored into `packages/pypi` + `packages/npm`; canonical template/writer/skill changes rendered to all profiles + dogfood via `run_generator.py`; `test-dogfood-byte-identity.sh` passes.
- [ ] Tests added/updated for the new schema parsing (both twins); existing tests pass.
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).

> **Task list + execution graph** now live in the flattened-work siblings — the delivery's task
> table and gate criteria are in `BLUEPRINT.md`, and the execution graph is in `PLAN.md`. Each
> task's full definition is `tasks/task-NNN/DETAIL.md` (no per-task STATE.md; task cells live in
> `STATE.md § ### Tasks lifecycle`). Beyond this STATE-frontmatter feature, delivery-001 also
> folds in 3 independent maintenance fixes (task-006 §6/section-6 refs, task-007 KB closure
> hygiene, task-008 `aid --version`) — see `BLUEPRINT.md § Scope`.

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-07-09 | Initial lite-path SPEC created | /aid-describe LITE-REFACTOR |
| 2026-07-09 | LITE-REVIEW loopback fixes: canonical edit targets, owned resync ACs, live migration count, §6→settings, split reader task (4→5 tasks) | /aid-describe LITE-REVIEW |
| 2026-07-10 | Reconciled to flattened conventions: task table → BLUEPRINT.md, execution graph → PLAN.md | scaffold migration (70895e8b) |
