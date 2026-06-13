# task-063: Dogfood render — FULL run_generator.py emits the 4 KB-domain canonical edits into .claude/ + 5 install trees

**Type:** CONFIGURE

**Source:** feature-007-kb-dashboard → delivery-009

**Depends on:** task-059, task-060, task-061, task-062

**Scope:**
- Run the **FULL** `python3 .claude/skills/aid-generate/scripts/run_generator.py` (NOT a per-script renderer, per MEMORY "render-drift full generator") so the canonical KB-domain edits from this delivery re-emit into **this repo's dogfood** `.claude/skills/**` and the **five install trees** (C7, PR-A). This is the **canonical → render → .claude dogfood** pipeline — the OPPOSITE of d008's hand-maintained `bin/aid` vendor-refresh.
- The four canonical edits to re-render: task-059 (`/aid-config` `kb_baseline` schema + `canonical/templates/settings.yml`), task-060 (`aid-summarize` 9-file path relocation), task-061 (`aid-discover` FR34 auto-trigger + FR35 baseline record), task-062 (`aid-housekeep` re-stamp + committed-path repoint).
- Verify the post-render gates are green: **render-drift** (all five install trees byte-identical to canonical emission), **deterministic-emission / emission-manifest** (`verify_deterministic` manifests current after the render), and the **ASCII-only** gate for any shipped script/text touched. Per MEMORY "INDEX.md canonical regen": if the KB INDEX is affected, regenerate via `canonical/scripts/kb/build-kb-index.sh` (not the `.claude/` copy).
- Do **not** hand-edit `.claude/skills/**` — they must be pure render output of the FULL generator (any drift = re-run the generator, never patch). The R11 blast-radius discipline applies: the three KB-domain producers + the `/aid-config` schema must re-render render-drift-clean across all 5 trees + `.claude/`.

**Acceptance Criteria:**
- [ ] The FULL `run_generator.py` was run (not a per-script renderer); `.claude/skills/{aid-config,aid-summarize,aid-discover,aid-housekeep}/**` + `.claude/templates/settings.yml` reflect the task-059..062 canonical edits, and so do the five install trees.
- [ ] The **render-drift** gate is green: all five install trees are byte-identical to canonical emission; no manual `.claude/**` edit exists (pure render output).
- [ ] The **deterministic-emission / emission-manifest** gate is green (manifests current after the render); INDEX regenerated via the canonical script if affected.
- [ ] The **ASCII-only** gate is green for any shipped script/text touched by the render.
- [ ] All §6 quality gates pass; the dogfood-rendered producers are available for the producer↔consumer test (task-066) and the end-to-end visual gate (task-067).
