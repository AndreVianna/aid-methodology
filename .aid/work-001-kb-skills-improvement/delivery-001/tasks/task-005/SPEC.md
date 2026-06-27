# task-005: aid-summarize alignment (objective/summary repoint + concept-spine section x7 profiles)

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-001

> Soft/degrade-gracefully dependency on task-010's spine doc -- task-005 renders the concept-spine
> section whether or not the spine is yet populated (it degrades to a no-spine-doc state); no hard
> ordering edge. Hard dep remains task-001 only.

**Scope:**
- Edit `canonical/skills/aid-summarize/references/state-generate.md` Step 3: repoint the
  section-description source from `intent:` to `objective:` (purpose noun-phrase) + `summary:`
  (one-sentence scope), FALLING BACK to `intent:` when `objective:`/`summary:` are absent (the same
  coexistence rule f001/f002 use), then to "first paragraph after H1". No `assemble.sh` change.
- Add an optional `audience:` role badge where a section renders a doc's metadata (light touch;
  renders nothing when `audience:` is absent).
- Add ONE concept-spine section entry to ALL 7 `section-templates/{profile}.md` profile files
  (`agentic-pipeline`, `auto-detect`, `cli`, `data-pipeline`, `library`, `microservices`, `web-app`)
  -- the native-terms + one-line-definitions spine block, authored from the C4 spine doc f004
  persists. Wording/diagram MAY be tailored per profile; every profile gets the section entry. Scope
  guard: one section per profile, NOT a redesign (hero/nav/CSS/Mermaid/lightbox + the other ~13
  sections untouched). `assemble.sh` globs `sections/*.html` and picks up the new numbered file with
  no script change.
- Edit canonical only; re-run `run_generator.py`; commit regenerated `profiles/`.

**Acceptance Criteria:**
- [ ] `state-generate.md` Step 3 reads `objective:`/`summary:` as the authoritative
  section-description source, falling back to `intent:` then to the first paragraph after H1;
  `assemble.sh` is unchanged.
- [ ] An optional `audience:` badge is surfaced from existing per-section metadata; absent
  `audience:` renders nothing (no layout change).
- [ ] All 7 `section-templates/*.md` profile files gain a concept-spine section entry; the other ~13
  sections, hero, nav, CSS, Mermaid pipeline, and lightbox are untouched.
- [ ] No `assemble.sh` / `fetch-mermaid.sh` / skeleton / CSS-JS / grade-validate-approval change.
- [ ] An un-migrated KB (no `objective:`/`summary:`/spine doc yet) still renders correctly via the
  fallbacks (degrade-gracefully).
- [ ] `run_generator.py` re-run; regenerated `profiles/` committed (render-drift green).
- [ ] All section-6 quality gates pass.
