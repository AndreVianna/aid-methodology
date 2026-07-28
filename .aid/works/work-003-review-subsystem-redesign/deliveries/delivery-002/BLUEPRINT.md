# Delivery BLUEPRINT -- delivery-002: Citation lint

> **Delivery:** delivery-002
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Make citation accuracy mechanical for work artifacts, and fix the eight SPECs this work has already
produced. Sequenced second, ahead of all severity work, because every finding across 33 review
cycles was a citation or count defect -- catching them by script is strictly cheaper than paying a
review cycle each time, and the corrected SPECs are the input every downstream DETAIL reads.

## Scope

- The en-dash tokenizer fix. All 25 range citations in the SPECs use U+2013; the current character
  class admits only an ASCII hyphen, so every upper bound is silently truncated.
- `--profile durable|resolvable` and `--depth N` on `kb-citation-lint.sh`.
- The resolver: verbatim `test -f`, then a suffix match over `git ls-files` **with a mandatory
  `find` fallback** -- `git ls-files` fails outright in this repository's own worktrees under WSL.
- The range check, and `[UNRESOLVED]` / `[AMBIGUOUS]` reporting.
- The fix commit on all eight SPECs.
- The false CI claim at `.aid/knowledge/quality-gates.md` 353-354, pulled forward from
  delivery-017: it states the citation lint is blocking for merges to master, and it has never run
  in CI.

**Out of scope:** the attributed-quote check and the INTAKE wiring (delivery-017); renaming the
script; the count-claim re-runner.

## Gate Criteria

- [ ] A range citation using an en-dash against a shorter file reports `[OUT-OF-RANGE]`
      (non-trivially false today -- the upper bound is currently invisible)
- [ ] `--profile durable` output on `.aid/knowledge` is byte-identical to today's
- [ ] The resolver falls back to a single `find` sweep when `git ls-files` exits non-zero, verified
      inside a worktree
- [ ] The three inherited exemptions stay silent under both profiles
- [ ] The eight SPECs exit 1 before the fix commit and exit 0 after
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** delivery-017

## Notes

The only delivery that depends on nothing. It gates nothing **outside its own feature** -- the
quote check at delivery-017 extends the script this delivery ships, so that one edge exists. Fully
independent upstream, so it is also the work available whenever the spine is blocked.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | Citation lint: profiles, resolver and range check |
| task-002 | MIGRATE | 2 | Fix commit on the eight SPECs |
