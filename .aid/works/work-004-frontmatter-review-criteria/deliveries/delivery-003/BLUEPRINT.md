# Delivery BLUEPRINT -- delivery-003: Retire + render -- remove the stand-ins and ship once

> **Delivery:** delivery-003
> **Work:** work-004-frontmatter-review-criteria
> **Created:** 2026-08-13

---

## Objective

Close the work: remove the prose-fact guards the declarations now replace, bring the user-facing front
face current, run the one render, and audit the `work-003` boundary. It is last because a guard cannot
be retired until the declaration that replaces it exists (delivery-001) and is populated (delivery-002),
and because the single render (C-2 / NFR-4) must happen after every source has stopped moving. This is
the only delivery that produces a shippable rendered state.

## Scope

Feature-003, all 8 technical-spec sections:

- Derive the removal set from disk (AC-3); assert no inherited inventory.
- Apply the `check-skill-counts.mjs` disposition: full-delete default, with each corpus part it cannot
  cede to the cascade given a named replacement or a stated coverage-drop (the narrow alternative is the
  flagged owner call).
- Bring the front face current: `docs/*.md` (7), root `README.md`, `examples/**/README.md` (4).
- Run the **single render** of both chains exactly once: `canonical/`->`profiles/`->the 2 dogfood trees
  (via `run_generator.py`, full run, then resync), and the site chain
  (`site/src/content/docs` + the 76 `*.flow.json`, regenerated).
- State the exit arithmetic: guard-line floor **379** kept separate from the 1,802 doc lines (never
  merged -- NFR-2).
- Run the C-7 audit over `imports-from-work-003.md`.

**Out of scope:** authoring criteria/readers (delivery-001); populating files or deleting the READMEs
(delivery-002). This delivery performs the only render in the whole work.

## Gate Criteria

- [ ] The removal set was derived from this branch's disk; every removed check names the declaration (or
      stated coverage-drop) that replaces it; `kb-citation-lint.sh` and `test-dogfood-byte-identity.sh`
      survive.
- [ ] The front face (`docs/`, root `README.md`, `examples/**/README.md`) describes the trees as they now
      are; all 4 `examples/` READMEs remain (all referenced).
- [ ] Both derived chains are refreshed **exactly once**; `test-dogfood-byte-identity.sh` passes against
      the result; the site flow sidecars are regenerated, not hand-edited.
- [ ] Exit arithmetic stated as a number: removed guard lines exceed added mechanism lines, with the 379
      guard floor and the 1,802 doc lines reported separately (never summed).
- [ ] The C-7 audit confirms no commit / cherry-pick / file copy from `work-003`; every
      `imports-from-work-003.md` entry passes all six gates.
- [ ] **AC-2 proof** passes: a defect of a removed check's class is caught by the replacing declaration.
- [ ] All section-6 quality gates pass.

## Tasks

*Defined by `/aid-detail`.*

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-002
- **Blocks:** -- (none)

## Notes

Owner judgment call carried from feature-003 SPEC §2: full-delete vs narrow of `check-skill-counts.mjs`.
Default is full delete (keeps the 379 floor); decided at execution against disk. This delivery is where
the byte-identity gate is first expected to pass.
