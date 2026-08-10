# Delivery BLUEPRINT -- delivery-019: Criteria and catalog additions

> **Delivery:** delivery-019
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-08-09

---

## Objective

Make four reviewer checks reportable as findings. Three are checks a reviewer brief already
instructs an agent to perform; the fourth -- resource cleanup -- is not instructed anywhere today
and becomes reportable for the first time. All four are currently **unwritable**: `review-rubrics/INDEX.md`'s
No-Criterion-no-row contract forbids a finding whose `Rule` cell names no declared rule, so an agent
that finds one can only re-register the same criteria gap on the next cycle, indefinitely. Scoped as
a distinct unit because two of the four need a KB criterion authored *before* a rule can cite it,
which is a different kind of change from adding a catalog row.

## Scope

- The temp-file/trap convention, authored into `.aid/knowledge/coding-standards.md § Shell (Bash)
  Conventions` via `/aid-update-kb` -- that section carries six bullets today (shebang, strict mode,
  `|| true`, argument parsing, YAML parsing, portability fallbacks) and none concerns temp files,
  traps, or guarding a destructive path.
- `EXE-14` in `review-rubrics/executable.md`, citing that new section. Resource cleanup joins the
  script-correctness family alongside `EXE-05` (exit codes) and `EXE-07` (error handling).
- The two kb-anatomy rules whose criteria **already exist**: content-vs-declared-purpose (declared
  at `kb-authoring/review-rubric.md § Rubric: Full Primary` item 2, a source `review-rubrics/kb.md`
  already cites 11 times -- the criterion exists but is keyed to the superseded `intent:`, so item 2
  is re-pointed at `objective:`/`summary:` and that is a criterion edit, not a new criterion) and undefined project-specific term (declared at
  `authoring-conventions.md § Dual-Audience Standard`, the section `KB-08` already cites).
- Item 11 authored into `kb-authoring/review-rubric.md § Rubric: Full Primary` for missing edge case
  / failure mode, then its rule citing it. Free IDs: `KB-10`..`KB-19`, `KB-27`+.
- Clearing the residual: `reviewer-prompt-anatomy.md` lines 60-62, 71-72 and 77-81 currently declare
  `[MEDIUM]` on the reviewer's own authority; once anchored they cite their rules instead.

**Out of scope:** the `intent:` frontmatter field's own retirement (this delivery re-points the rule at
`objective:`/`summary:` and updates the criterion to match, but does not migrate the field); any
rubric family other than `executable` and `kb`.

## Gate Criteria

- [ ] `coding-standards.md § Shell (Bash) Conventions` states the temp-file/trap convention, and
      `EXE-14`'s `Criterion` cell cites that section by name and resolves
- [ ] `EXE-14` fires on a script that installs no cleanup trap, and only on those. Stated as the
      invariant rather than a count, because the totals move whenever a script is added:
      `grep -rl mktemp canonical/aid/scripts/ | xargs grep -L 'trap '` returns exactly
      `execute/write-control-signal.sh`, `housekeep/housekeep-state.sh` and
      `migrate/migrate-work-hierarchy.sh` -- a sweep reports those three and no other `mktemp` caller
- [ ] Three new `kb` rules exist, each with a `Criterion` cell naming a section that exists on disk;
      no rule invents a criterion
- [ ] The content-vs-purpose rule is keyed to `objective:`/`summary:`, not the superseded `intent:` --
      `grep -l '^intent:' .aid/knowledge/*.md` returns 13 of 22, so an `intent:`-keyed rule would be
      dead on the rest
- [ ] Every checklist item **this delivery anchors** cites its rule in `reviewer-prompt-anatomy.md`
      rather than declaring a severity on the reviewer's own authority -- lines 60-62, 71-72 and
      77-81, which are exactly the three self-declared `[MEDIUM]`s. Items this delivery does not
      anchor are out of its reach and are not asserted here
- [ ] `tests/canonical/test-review-rubrics.sh` passes with the added rows, each in the band its
      modality and blast radius select
- [ ] All section-6 quality gates pass

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. Written by `aid-detail`; empty until it runs._

| Task | Type | Wave | Title |
|------|------|------|-------|
| _none yet_ | | | |

## Dependencies

- **Depends on:** delivery-004
- **Blocks:** delivery-022

## Notes

**Two of the four are nearly free and two are not.** The content-vs-purpose and undefined-term rules
cite sections already in use by this catalog, so they are row additions. The temp-file rule and item
11 each require authoring a criterion first, but **through different routes, because the two
criteria live in different trees.** The temp-file criterion is a KB change -- it lands in
`.aid/knowledge/coding-standards.md`, so it routes through `/aid-update-kb`. Item 11's criterion
lands in `canonical/aid/templates/kb-authoring/review-rubric.md`, which `/aid-update-kb` cannot
reach: its scope table is keyed to `.aid/knowledge/<doc>.md` (`state-scope.md`) and its APPLY step
derives the changed set with `git status --porcelain -- .aid/knowledge/` (`state-apply.md`). That
one is authored here, as a canonical-template edit.

**Expect the undefined-term rule to LOWER a severity.** Its peer bullets became `KB-05`..`KB-08`, all
banded `SHOULD` -> `[LOW]` escaped `(>1 doc)` -> `[MEDIUM]`. The checklist currently self-declares
`[MEDIUM]`. The predicates also differ and must be reconciled: the KB says *define it in
`domain-glossary.md`*, the checklist flags a term undefined *within the doc's own scope*.

**Not reframed onto `KB-24`.** That rule would raise the edge-case check `[MEDIUM]` -> `[HIGH]` and
is act-back-scoped -- `state-review.md` counts rows whose id begins `AB-` and whose Rule matches
`^KB-2[0-6]$` into the assertiveness verdict.
