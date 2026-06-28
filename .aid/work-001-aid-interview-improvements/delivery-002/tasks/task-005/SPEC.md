# task-005: refresh docs/repository-structure.md (M3)

**Type:** DOCUMENT

**Source:** work-001-aid-interview-improvements -> delivery-002

**Depends on:** -- (none)

**Scope:**
- Reconcile **`docs/repository-structure.md`** (the named M3 target; NOT a `.aid/knowledge/` KB doc)
  against the live tree so it stops misreporting: correct the skill/recipe COUNTS and ALL THREE
  in-doc `canonical/<x>/` -> `canonical/aid/<x>/` path drifts (templates, recipes, scripts) in BOTH
  the prose AND the L21-26 ASCII directory tree.
- Counts MUST be derived from the live tree at run time, not transcribed:
  `ls -d canonical/skills/*/ | wc -l` (skills) and `ls canonical/aid/recipes/ | wc -l` (recipes) --
  they may drift again before execution.
- The ASCII tree must show the `aid/` node with templates/recipes/scripts nested UNDER it; nowhere
  in prose or the tree may templates/recipes/scripts appear outside `canonical/aid/`.
- May be executed as a targeted `/aid-housekeep` run scoped to the skill-/recipe-count + the three
  path drifts with `docs/repository-structure.md` as the named target (feature-007's sanctioned
  mechanism); the deliverable is the corrected doc on disk, however produced.
- Update the **`.aid/knowledge/tech-debt.md` M3 row** to resolved (or scoped-remainder noted) -- this
  is part of M3's closure (feature-007 M3 closure criteria). This is the ONLY KB file touched.
- Out of scope (per feature-007 M3): the sibling source-doc drifts in `docs/aid-methodology.md` and
  `canonical/EMISSION-MANIFEST.md` -- not part of M3's closure (may be folded by housekeep if cheap,
  not required here). No other doc is rewritten beyond the repository-structure.md target + the
  tech-debt.md M3 row.

**Acceptance Criteria:**
- [ ] `docs/repository-structure.md` skill/recipe counts match a fresh live re-count (`ls -d canonical/skills/*/ | wc -l`, `ls canonical/aid/recipes/ | wc -l`). *(M3)*
- [ ] All three paths (templates, recipes, scripts) read `canonical/aid/<x>/` in BOTH prose and the L21-26 ASCII tree; nothing depicts them outside `canonical/aid/`. *(M3 closure)*
- [ ] The `.aid/knowledge/tech-debt.md` M3 row is updated (resolved or scoped-remainder noted). *(M3 closure, SPEC L175)*
- [ ] Accuracy verified against the current tree; no doc altered beyond `docs/repository-structure.md` and the tech-debt.md M3 row (the `docs/` source auto-syncs to its `site/` copy via `site/scripts/sync-docs.mjs`). *(DOCUMENT default + scope boundary)*
- [ ] KB-hygiene / CI stays green; INDEX.md regen via canonical `build-kb-index.sh` only if the tech-debt.md INDEX summary line actually changed (a status-row flip normally does not). *(index-md-canonical-regen, scoped correctly to the KB file)*
- [ ] All REQUIREMENTS.md §6 quality gates pass.
