# task-050: f010 behavioral guards -- suspect scoping + before-commit closure re-verify

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-008

**Depends on:** task-049

**Scope:**
- f010 CI / verification (SPEC "CI / verification") -- f010 ships NO new script, so its acceptance
  is behavioral: assert the rewritten skill bodies via deterministic guards. Add the guards as a
  small `tests/canonical/` assertion (or a doc-grep added to an existing skill-shape test), keeping
  f010 dependency-free. No new script is tested at the script level (f004's
  `test-closure-check.sh` and f007's freshness suite already cover the two helpers).
- **Cross-delivery citation:** the guards assert the task-049 rewrite of
  `canonical/skills/aid-housekeep/references/state-kb-delta.md` and reference
  `canonical/skills/aid-update-kb/references/state-done.md` (task-043/f008, the update-kb closure
  half) -- they do not modify either skill body.
- **Guard 1 (FR-33 / AC10 -- suspect scoping):** assert `state-kb-delta.md` references
  `kb-freshness-check.sh` (the suspect pre-pass is wired) AND no longer relies on a git-date range
  as the scoping boundary (the git range survives only as an optional convenience hint, not as the
  drift signal that bounds the review). Phrase the negative guard against the SPEC's intent
  precisely so it does not false-fail on the retained convenience-hint mention.
- **Guard 2 (FR-33 -- whole-KB review retained):** assert `state-kb-delta.md` still mandates the
  whole-KB content re-review of all docs (the AC1 guarantee is not narrowed to suspect-only) --
  e.g. the doc continues to require reviewing `current`/all docs, not just the suspect set. This
  guard is the safety net against a future edit silently narrowing coverage to suspect-only.
- **Guard 3 (FR-34 -- before-commit closure re-verify, both skills):** assert BOTH
  `aid-housekeep/references/state-kb-delta.md` (passed path, before the KB-DELTA commit) AND
  `aid-update-kb/references/state-done.md` reference `closure-check.sh` before committing -- the
  shared standing-invariant contract across both KB-mutating paths.
- Guards are deterministic, run in CI alongside the existing canonical suites, and have clean
  setup/teardown (read-only greps over committed canonical source -- no fixtures to tear down).
- ASCII-only (C2) for any added test script.

**Acceptance Criteria:**
- [ ] A guard asserts `state-kb-delta.md` references `kb-freshness-check.sh` and no longer uses a
  git-date range as the scoping boundary (git range is convenience-only). *(FR-33/AC10)*
- [ ] A guard asserts `state-kb-delta.md` retains the whole-KB content re-review of all docs (AC1
  coverage not narrowed to suspect-only). *(FR-33)*
- [ ] A guard asserts BOTH `aid-housekeep/references/state-kb-delta.md` (before its KB-DELTA commit)
  AND `aid-update-kb/references/state-done.md` reference `closure-check.sh` before committing.
  *(FR-34)*
- [ ] The guards are wired into CI (a `tests/canonical/` assertion or an existing skill-shape test)
  and pass against the task-049 rewrite.
- [ ] Tests are deterministic with clean setup/teardown.
- [ ] All acceptance criteria from feature-010 that are testable at the doc/skill-body level are
  covered by these guards.
- [ ] Any added test script is ASCII-only.
- [ ] All section-6 quality gates pass.
