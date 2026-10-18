# h004: quick reviews of task-370 and task-020

**From:** Claude. **To:** Codex. **Type:** review only. Read `handoff/PROTOCOL.md` first. Start only
when `NEXT.md` names h004.

Two independent task reviews in one job. For each, read the task file in full, then check the task's
commit against **every** acceptance criterion and its Scope. Report what does not hold, with a path and
a line a reader can check. Same rules as h001: no fix, no grade, no other file.

## Review 1: task-370 (conversation runner fixes from your h001 findings)

- Task file: `.aid/works/work-003-full-aid-restructure/deliveries/delivery-001/tasks/task-370/DETAIL.md`.
- Change: `git show f14e594d -- tests/conversation/run.py tests/canonical/test-conversation-runner.sh`.
- Check each of your four h001 findings is truly fixed, with no new hole of the same kind (for example
  another push wrapper, or another cell-splitting path). Check each new case fails its own mutation.
- The suite runs in about a minute: `HOME="$(mktemp -d)" bash tests/canonical/test-conversation-runner.sh`.
- Known and accepted: a symlink entry shows in `files.diff` as `Binary file ... (N bytes)`, without its
  target text. Report it only if an acceptance criterion needs the target visible.
- Ledger: `.aid/works/work-003-full-aid-restructure/analysis/task-370-review-codex.md`.

## Review 2: task-020 (delivery-002 site search, research only)

- Task file: `.aid/works/work-003-full-aid-restructure/deliveries/delivery-002/tasks/task-020/DETAIL.md`.
- Output: `.aid/works/work-003-full-aid-restructure/research/delivery-002-sites.md` (commit `8e7edf0c`;
  base `06d32a1b`, named in the file).
- Check the acceptance criteria, especially: each P1-P10 command reproduces its hits at the base
  (`git grep ... 06d32a1b -- ...`); every hit has exactly one owner; the skill owner table has one row per
  `canonical/skills/*/SKILL.md` at the base; owners match what each task's Scope actually edits
  (task files `deliveries/delivery-002/tasks/task-021` to `task-057`). Sampling is fine for the
  large P5, P8 and G11 tables: check at least 20 rows of each, chosen across the table.
- The builder flagged five judgement calls. Say for each whether you agree, in a ledger row
  (`[LOW]` if you agree and it needs nothing; higher if it is wrong):
  1. "history, left as is" also covers spec items "left as they are", synthetic fixture names and
     hits on skills no task edits (its delta D9);
  2. `state-machine-chaining.md` hits owned by task-050, although task-074 (delivery-003) deletes the
     file (D7);
  3. the flow-graph library files `extract-inline.mjs`, `extract-dispatch.mjs`, `model.mjs` and
     `engine-core.mjs` owned by task-024, which no task Scope names;
  4. `test-describe-full-only.sh` is named by the spec's Tests rule but by no task Scope (D10);
  5. the tenth `--field Phase` write site, `aid-orchestrate` `size-and-route.md`, and
     `aid-orchestrate/SKILL.md:47`, are missing from the spec's phase-sites table (D3).
- Ledger: `.aid/works/work-003-full-aid-restructure/analysis/task-020-review-codex.md`.

## Output

- The two ledgers above, each a single 7-column table (`# | Severity | Status | Doc | Line |
  Description | Evidence`), Status `Pending` on every row.
- `handoff/replies/h004.md` as `PROTOCOL.md` § A job, step 5 says.
- Commit those three files together as `h004: Codex reviews of task-370 and task-020`, push, and tell
  the maintainer: "h004 done".
