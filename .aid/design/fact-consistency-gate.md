# Design Note — Cross-Surface Fact-Consistency Gate

**Status:** Pre-scoping — NOT yet a tracked work. Captured 2026-06-29 (post-v2.0.0), while the
evidence is fresh. Recommended as the next work (highest leverage of the four 2026-06-29 seeds).

**Motivation.** AID states the same *load-bearing facts* in many places — "14 skills", "9 agents",
"5 host tools / profiles", "6 numbered phases", the phase names and order, the publish-channel list.
Each fact is duplicated across the KB docs, the docs site, `kb.html`, the READMEs, and several tests.
When one changes, every copy must be hand-updated, and a miss ships a self-contradiction. AID is sold
to AI-skeptical adopters where *predictable, non-sloppy output is the product* — a doc that contradicts
itself is exactly the "slop" signal that loses them. This gate makes self-contradiction **impossible to
merge**.

---

## Problem

Fact duplication with no enforcement. Concrete drift hit during the v2.0.0 line alone:

- The `gen-reference` site test asserted "**exactly 11** skill sections" long after the count became 14
  — a stale test that PR CI never failed (the site vitest lane wasn't wired into the gate).
- The Phase-2 relabel (Interview → Describe → Define) had to be hand-applied across **~10 KB docs +
  the site + `kb.html` + CLAUDE.md + tests** — easy to miss a surface (and it was: a real
  `2·Interview` vs `2·Define` contradiction existed in the methodology Mermaid).
- KB diagram labels encoded counts ("14 skills", "9 agents") with no check that they matched reality.
- Known recurring pain (in maintainer memory): "adding/removing a skill leaves 'N user-facing skills'
  counts stale across ~10 KB docs; CI misses it; reconcile by hand."

Two **point** solutions already exist but don't generalize:
- `check-version-sync.sh` — asserts the version carriers agree (VERSION + package.json + pyproject + tag).
- `validate-diagram-content.mjs` + `diagram-content-manifest.json` (shipped 2.0.0) — asserts each
  `kb.html` diagram carries its required tokens / no stale tokens.

Both prove the pattern works. The gap is a **single, general** mechanism for *all* enumerable facts
across *all* surfaces.

## Proposed approach

1. **One source of truth.** A small facts registry — either an authored manifest (`facts.yml`) or, better
   where possible, **derived** values so they can't go stale (e.g. skill count = `ls -1d canonical/skills/*/`,
   agent count = `canonical/agents/*`, profile count = `profiles/*.toml`, phase names from one canonical
   list). Authored only for facts with no natural derivation.
2. **A consistency check (CI).** Assert every consuming surface matches the source of truth. Surfaces:
   KB docs (`.aid/knowledge/`), the docs site (`site/`), `kb.html` (reuse the diagram-content gate),
   the READMEs, and the count-asserting tests.
3. **Generalize, don't multiply.** Fold `check-version-sync` and `validate-diagram-content` conceptually
   under this one "facts stay consistent everywhere" umbrella (they can remain separate scripts, but
   under one documented contract + one reference doc, à la `diagram-content-reference.md`).

## Key decisions / options to settle in scoping

- **Derive vs author** each fact (prefer derive; authored facts are themselves drift risk).
- **How a surface declares the facts it references** — explicit markers/annotations vs. grep patterns.
  Grep is zero-friction but false-positive-prone; markers are precise but require authoring discipline.
- **Flag-only vs auto-fix.** Start flag-only (a CI failure naming the divergence); auto-fix is a later nicety.
- **Historical-reference safety (critical).** Must NOT rewrite legitimate "since v1.1.1" / "removed in
  v1.1.0" / changelog markers. The check must distinguish *current-state* facts from *historical* mentions
  (the same lesson the Phase-2 relabel taught: keep `## Interview State`, the `aid-interviewer` agent, etc.).
- **Scope of facts** — start with the high-drift set (skill/agent/profile counts, phase names+order,
  channels); expand later.

## Scope boundaries

Not a general spell-check or prose linter. Strictly the enumerable, load-bearing facts that have one
correct value and recur across surfaces.

## Relation to other work

Extends `check-version-sync.sh` (work-005) and the `diagram-content-manifest` (v2.0.0). Pairs naturally
with the "CI stronger + faster" seed (both are CI-quality). Directly serves the no-slop / trust promise.
