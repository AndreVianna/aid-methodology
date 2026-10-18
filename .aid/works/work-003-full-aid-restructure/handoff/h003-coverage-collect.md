# h003: collect the test-coverage inventory on the Codex machine (revision 2)

**Revision 2:** the first run stopped because `pwsh` is missing (`replies/h003.md`). Add
`--allow-missing-runtime` to `collect` and `diff`, as below. Claude's machine has `pwsh` and covers the
PowerShell assertions, so a gap there on your side is expected. Do not install anything. Overwrite
`replies/h003.md` with the new reply.

**From:** Claude. **To:** Codex. **Type:** run tests, write two output files. Read `handoff/PROTOCOL.md`
first. Start only when `NEXT.md` names h003.

## Why

The delivery-001 gate re-records `tests/coverage-baseline.tsv`, the list of every test assertion that
runs. Claude's machine runs as root and has no `en_US.UTF-8` locale, so 29 assertions cannot run
there. Your machine has neither limit. Your inventory fills that gap (Q153).

## Steps

1. `git pull origin work-003`. Note the head commit.
2. From the repository root, run (it takes 15 to 40 minutes; it changes no tracked file by design):

   ```sh
   W=.aid/works/work-003-full-aid-restructure
   AID_COVERAGE_JOBS=4 HOME="$(mktemp -d)" bash tests/coverage-parity.sh collect \
     --out "$W/analysis/coverage-codex.tsv" --allow-missing-runtime > /tmp/h003-collect.log 2>&1; echo "collect exit=$?"
   bash tests/coverage-parity.sh diff --baseline tests/coverage-baseline.tsv \
     --after "$W/analysis/coverage-codex.tsv" \
     --allow tests/coverage-rehome-allowlist.tsv \
     --accept tests/coverage-accepted-removals.tsv --allow-missing-runtime > /tmp/h003-diff.log 2>&1; echo "diff exit=$?"
   ```

   `collect` writes `coverage-codex.tsv` and its sidecar `coverage-codex.meta`. A non-zero `diff`
   exit is expected: report it, do not fix anything.
3. Run `git status --short`. The only new files should be the two outputs above. If a suite changed
   any tracked file, list each path in your reply, then put it back with `git restore -- <path>`.
   Delete nothing.

## Reply

Write `$W/handoff/replies/h003.md` with:

- `status: done | partial | blocked`;
- the head commit you ran on;
- both exit codes;
- the `-- REMOVED / REDUCED (un-excused) --` section of `/tmp/h003-diff.log`, copied as is;
- the names of the suites whose assertions failed, from `/tmp/h003-collect.log`, each with one line on
  why if the log shows it (missing tool, network, and so on);
- any tracked file a suite changed (step 3), or "none".

## Files you may write

- `$W/analysis/coverage-codex.tsv`
- `$W/analysis/coverage-codex.meta`
- `$W/handoff/replies/h003.md`

Commit those three together with the message `h003: Codex coverage inventory`, push, and tell the
maintainer: "h003 done".
