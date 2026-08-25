# task-034 — the rest of the instruction surface, same test

Task-033's test, applied unchanged: **an instruction is executed, documentation is read.**

## Converted — instruction

| File | Sites |
|---|---|
| `aid-deploy/state-verifying.md` | 4 — append a row, the `grade.sh` call, two `rm -f` cleanups |
| `aid-summarize/state-validate.md` | 2 |
| `aid-summarize/state-done.md` | 1 |
| `aid-summarize/state-fix.md` | 1 |
| `aid-detail/first-run.md` | 2 |
| `aid-detail/review.md` | 3 |
| `aid-plan/first-run-loop.md` | 2 |
| `aid-plan/review-deliverables.md` | 3 |

**18 sites, all now `{{LEDGER}}`.**

`aid-summarize/state-fix.md` was not in this task's stated file list and was found by the canary
rather than by reading the scope. It is the same shape task-033 converted in `aid-discover` — an
unconditional `Read <literal>` at the start of a FIX state — so a list of files was the wrong way
to enumerate this group, and the measurement was the right one.

## Kept — documentation

| Site | Why |
|---|---|
| `aid-housekeep/state-cleanup.md` | sample output inside a file listing; it shows what a real run prints |
| `aid-update-kb/SKILL.md` | prose describing where findings are written; executes nothing |
| `reviewer-dispatch.md` § Worked example | a transcript of one real dispatch (task-031's call, unchanged) |
| `reviewer-ledger-schema.md` § path table | the per-skill ledger paths, which is a reference table and the thing a reader comes to it for |
| `kb-authoring/review-rubric.md` | prose describing where `/aid-discover` writes |

## The canary

```
$ grep -rn 'review-pending/[a-z0-9-]*\.md' canonical/skills --include='*.md' | grep -vc '{{'
2
```

Both remaining are documentation, named above. **Zero literal paths survive in the instruction
surface**, measured at 31 across 37 files in task-026's baseline.

The figure recorded is zero-in-the-instruction-surface rather than a total token count, for the
reason task-033 learned the hard way: a token count moves whenever anyone writes the word, and had
to be corrected twice before it settled.
