# task-010: Reconcile the phase model to the real pipeline (faithful) + distinct Lite display

**Type:** REFACTOR

**Source:** work-003-state-schema -> delivery-001

**Depends on:** task-002, task-004, task-005

**Scope:**
User-flagged: the dashboard phase stepper is "completely wrong." Root cause: the machine `Phase`
enum never followed the 2026-06-28 PROSE rename (`Interview` -> `Describe -> Define`,
`architecture.md` changelog v1.3), so the enum is frozen at a retired model
(`Interview | Specify | Plan | Detail | Execute | Deploy | Monitor`). USER DECISIONS: (1) rebuild
the **Faithful 6-phase model**; (2) the **Lite/shortcut path must display DIFFERENTLY** from the
full path. This is an end-to-end enum migration (schema + writer + skills + both reader twins +
dashboard + vendored trees + on-disk data + back-compat), NOT a display-only tweak.

### Ground truth to encode (from `.aid/knowledge/architecture.md:175-208`, `pipeline-contracts.md`)
Full-path pipeline phases: **Discover -> Describe -> Define -> Specify -> Plan -> Detail -> Execute**.
- `aid-config` = bootstrap (NOT a phase).
- **Discover** (`aid-discover`) is KB-level — it writes the KB discovery-area STATE (`kb_status`
  vocabulary), NEVER a work `phase:`. Surface a Discover indicator in the full stepper derived
  from **KB state** (`KbStatus` on the model), not from a work `phase:` write.
- **Describe** (`aid-describe`) + **Define** (`aid-define`): SPLIT the retired single "Interview"
  value into these two distinct phases — `aid-describe` writes `Describe`, `aid-define` writes `Define`.
- **Specify / Plan / Detail / Execute**: already correct write-values; keep.
- **Deploy**: optional post-pipeline Deliver skill (`aid-deploy` pipeline mode writes `phase: Deploy`)
  — render it as a **separate optional post-Execute indicator**, NOT a linear pre-Execute stepper slot.
- **Monitor**: DEAD enum value — NO skill ever writes `phase: Monitor` (confirmed by grep). REMOVE
  the enum value. (Keep the `monitor` **shortcut verb** in `shortcut-catalog.yml` — that is unrelated.)

### Lite / shortcut path — a DISTINCT display (user requirement)
The shortcut engine's real states are `INTAKE -> CAPTURE -> SPEC -> PLAN -> DETAIL -> GATE ->
APPROVAL-HALT` (halts pre-Execute), then `aid-execute`. The Lite/shortcut work MUST render a
**different** phase display from the full 6-phase stepper — keep task-002's compact
**Defining -> Executing -> Done** rail (or a shortcut-vocabulary equivalent), but drive it from the
CORRECT signal (`work_path == 'lite'` + the real lifecycle/phase), NOT by reinterpreting the stale
full-path index the way `_renderLiteStageRail` does today. Full path -> 6-phase stepper; Lite path
-> distinct compact rail. (Propose Defining->Executing->Done, already accepted for task-002; open to
redirect.)

### The end-to-end change (every encoded location — keep 3 vendored trees + 2 twins in lockstep)
1. **STATE templates** — `canonical/aid/templates/work-state-template.md`: frontmatter `phase:` enum
   (~:9), body `> **Phase:**` blockquote (~:80), "Phase enum:" comment (~:104), the `> **State:**`
   line (~:79). Check the other state templates for the enum too.
2. **Writer validation** — `canonical/aid/scripts/execute/writeback-state.sh` phase-enum validation
   (~:1381-1382) + doc comment (~:1320): accept the new enum, reject the old-only values (with a
   back-compat note if needed).
3. **Skill write-sites** — `canonical/skills/aid-describe/references/state-first-run.md:40`
   (`Interview`->`Describe`), `canonical/skills/aid-define/references/state-feature-decomposition.md:8`
   (`Interview`->`Define`), `canonical/aid/templates/shortcut-engine.md:274` (INTAKE seed) + :614-616
   (GATE note). Verify specify/plan/detail/execute already write the correct values.
4. **Reader Phase enum (BOTH twins)** — `dashboard/reader/models.py:40-55` (`Phase` enum) +
   `parsers.py:2207-2214` (`_PHASE_MAP`) + `dashboard/server/reader.mjs:74-81` + :386-393
   (`PHASE_MAP`). Add the new members; keep Python/Node identical.
5. **Dashboard** — `dashboard/home.html`: `PHASE_ORDER` (~:928) -> the faithful ordered full-path
   list; `PRE_EXEC_STEPS`/readiness math (~:1413) recount for the new pre-Execute count; Discover
   indicator from KB state; Deploy as a post-Execute optional indicator; `renderStageRail` (full) +
   `_renderLiteStageRail` (lite, distinct) reconciled to the new model; update the now-stale
   Interview/Deploy/Monitor comments (~:1410, 2210-2246). Mirror to the served `.aid/dashboard/home.html`.
6. **Back-compat + data migration (no rollout regression)** — the reader MUST still read legacy
   `phase: Interview` (task-005 already migrated on-disk STATE files + fixtures carry it): add a
   reader alias `Interview` -> `Describe` on BOTH twins so old files/fixtures don't break; AND migrate
   the on-disk `.aid/work-*/STATE.md` + `dashboard/*/tests/fixtures/**` from the old values to the new
   (`Interview` -> `Describe`/`Define` as appropriate) so the repo is self-consistent. Update
   `dashboard/reader/tests/*` that assert the old enum.
7. **Re-render + re-vendor** — `python .claude/skills/generate-profile/scripts/run_generator.py`
   (templates/skills changed) + resync dogfood `.claude/`; re-vendor the dashboard reader into
   `packages/npm` + `packages/pypi` (folds into the final ship). Byte-identity/parity deferred to CI.

**Acceptance Criteria:**
- [ ] The `Phase` enum is the faithful pipeline set (`Discover`/`Describe`/`Define`/`Specify`/`Plan`/`Detail`/`Execute`, + `Deploy` as optional post-Execute); the dead `Monitor` value is removed; encoded consistently across template, writer-validation, the skill write-sites (Describe/Define split), and BOTH reader twins (traces to BLUEPRINT gate criteria #16).
- [ ] The dashboard full-path stepper renders the faithful phases (Discover surfaced from KB state; Deploy as a post-Execute indicator; no Interview/Monitor pills); `PRE_EXEC_STEPS`/readiness recomputed (traces to gate criteria #16).
- [ ] The Lite/shortcut path renders a DISTINCT display from the full stepper, driven by the correct model signal (not the stale full-path index) (traces to gate criteria #14, #16).
- [ ] Back-compat: both reader twins still read legacy `phase: Interview` (alias -> Describe); the on-disk STATE files + reader fixtures are migrated to the new values; reader/parity tests updated + green (traces to gate criteria #6, #16).
- [ ] `run_generator.py` re-rendered + dogfood resynced; reader re-vendored into both package trees; both home.html copies byte-identical (byte-identity/parity deferred to CI).
- [ ] All applicable quality gates pass (per `.aid/settings.yml`).
