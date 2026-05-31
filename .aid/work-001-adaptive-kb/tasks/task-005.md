# task-005: Remove orphan ui-architecture stub + correct stale profile-README tables

**Type:** IMPLEMENT

**Source:** feature-003-orphan-stub-cleanup → delivery-001

**Depends on:** — (none)

**Scope:**
- `git rm canonical/templates/ui-architecture.md` (R1).
- `python run_generator.py` — the manifest deletion pass auto-handles R2–R7 (the 3 rendered copies + the 3 `profiles/*/emission-manifest.jsonl` entries).
- Hand-edit the 8 stale README rows (C1–C8) in `profiles/claude-code/README.md` (~L51–54) and `profiles/cursor/README.md` (~L54–57) to the current doc-set, with values pinned to `state-generate.md:69–72`.
- Do NOT touch: the `/aid-summarize` `.aid/` KEEP signals (downstream heuristics — auto-detect.md/web-app.md), `profiles/codex/README.md` (its "16 documents" literal is task-008 / FR-P0-4 scope), or `canonical/EMISSION-MANIFEST.md` (prose, no ui-architecture entry).
- Guard against an over-broad grep-delete: never delete by `grep ui-architecture` — only the enumerated targets.

**Acceptance Criteria:**
- [ ] `find . -name ui-architecture.md` returns only the KEEP/`.aid/` items named in F3's SPEC — no `…/templates/ui-architecture.md` (canonical or any `profiles/*` render) and no `profiles/*/README.md` row referencing it.
- [ ] `grep -l ui-architecture profiles/*/emission-manifest.jsonl` returns nothing.
- [ ] `python run_generator.py` reports `Deleted: 1` per profile on the first post-removal run and `Deleted: 0` on an immediate second run (idempotent).
- [ ] The 8 README rows match the `state-generate.md:69–72` doc-set; `.aid/` summarize signals and the codex README are untouched.
- [ ] All §6 quality gates pass (render-drift clean, 13 suites green). *(Verification folded here per the SPEC's grep/find post-conditions — no dedicated suite.)*
