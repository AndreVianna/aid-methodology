# Delivery-003 gate: hand-off

For the session that finishes the delivery-003 gate of work-003 on branch `work-003`. Everything below is
committed. Read `.aid/runtime/rules.md` first, as `CLAUDE.md` requires.

## Where it stands

| Item | State | Evidence |
|---|---|---|
| Delivery-003 tasks 058-081 | All 24 Done | `deliveries/delivery-003/` task states |
| Delivery review and verify (Q166) | Done | `analysis/delivery-003-review-a1..a4.md`, `-verify-a1..a4.md`, `-c2.md`, `-c3.md` |
| Gate, first attempt | Samples failed; everything else passed | STATE.yml history, "Delivery-003 gate, first attempt" |
| Sample fix round (Q166, Q169-Q172) | Done | `analysis/delivery-003-gate-fix-design.md`; ledgers `delivery-003-gfix-review.md`, `-gfix-verify.md`, `-gfix-verify2.md`, `-gfix-verify3.md` (clean) |
| Full suite after the fixes | Pass, except the 9 machine-limit suites | see "Known failures" below |
| Site tests | 2822 of 2822 | `(cd site && npx vitest run)` |
| Resync | Committed alone | `a3dbfe25`; `test-dogfood-byte-identity` 625/0 |
| `/reload-skills` | Run by the maintainer | -- |
| Installer CI | Green on the resync commit | Installer CI run 2256 |
| KB index | Unchanged (timestamps only) | `build-kb-index.sh` |
| Coverage baseline | Re-recorded, Q153 method, no real loss | `0def8408` |
| Cost baseline | Re-recorded in the first attempt | `b3727800` |
| **Sample re-run** | **Not done: the only open gate item** | see below |

## What is left

1. **Re-run the 9 failing samples, 3 runs each**, in the live tree, at most 4 at a time. The runner needs the
   sample's full id (the file name without `.md`):

   ```bash
   cd /home/user/aid-methodology
   for n in 01 02 03 04 14 16 17 18 19; do
     f=$(ls tests/conversation/samples/feature-002/002-$n-*.md); id=$(basename "$f" .md)
     python3 tests/conversation/run.py --feature 002 --sample "$id" --runs 3 > "/tmp/$id.log" 2>&1
   done
   ```

   A run that ends with "Not logged in" or "session limit" is not a result: re-run it.
2. **Apply Q166:** a sample that still fails becomes a known issue to re-check at delivery-014. This is the one
   fix round; there is no second. Safety samples (never-merges and similar) block until they pass. Record the
   known issues in the gate report.
3. **Write the gate report** `analysis/delivery-003-gate.md` in the shape of `analysis/delivery-002-gate.md`:
   the stanza criteria, G0, and the sample results per attempt, with what the fix round changed.
4. **Close the delivery** through the writer, and add a STATE.yml history entry:

   ```bash
   W=.aid/works/work-003-full-aid-restructure
   export AID_STATE_FILE=$W/STATE.yml AID_WORK_DIR=$W
   bash canonical/aid/scripts/execute/writeback-state.sh --delivery-id 003 --lifecycle Gated
   bash canonical/aid/scripts/execute/writeback-state.sh --delivery-id 003 --gate-field Grade --gate-value '<grade>'
   bash canonical/aid/scripts/execute/writeback-state.sh --delivery-id 003 --gate-field Timestamp --gate-value '<UTC ISO time>'
   bash canonical/aid/scripts/execute/writeback-state.sh --delivery-id 003 --lifecycle Done
   ```
5. Commit and push to `work-003` only. Then tell the maintainer that delivery-004 is next.

## What the fix round changed (for the report)

- **Before a work exists (Q169):** every question asked then, with its answer, is recorded in a design document
  under `.aid/design/` (`--ask --design`, `--answer --design`; ids D1, D2, ...). Its `## Questions` table has the
  columns id, question, answer, state, answered_by, category. Design-stage skills (`aid-brainstorm`, `aid-design`,
  21 `aid-design-<kind>`) open no work. A question asked before the subject is known opens
  `.aid/design/untitled-<YYYYMMDD-HHMMSS>.md`, which `--rename-design <from> --to <to>` moves or merges later.
  Every starter's `--create` passes `--seed <document>`, which moves the questions into the work's qa. In a
  linked worktree, the main checkout's copy wins when it differs. Suite: `tests/canonical/test-design-no-work.sh`.
- **`--by` removed (Q170):** the writer alone sets `answered_by`.
- **Root causes 1 and 2:** in `rules.md`, any message that waits on a reply counts as a question, and the
  workflow proposal is one confirmation question in the form. `aid-monitor`, `aid-report` and `aid-review` ask in
  the form and record. `aid-config` has a walk mode (groups, a break between groups, skipped questions offered
  again). `aid-set-connector` asks no obvious name and offers only usable connection types.
- **Samples:** the 002-16 and 002-18 answer sheets say "say yes and nothing more"; `protocol-checks.md` accepts
  `answered_by: --` and checks for a break only between groups.
- **Backlog:** W7-19 removed (done); W7-35 (several `--seed` documents) and W7-36 (a lifecycle for question
  documents) added.

## Standing rules

- Q141: Haiku builds, Sonnet does the quick review, fix rounds use Sonnet. Q142: the per-task bar is C-.
- Q166: one full Opus review, one fix round, one verify. A recurred row or a new HIGH/CRITICAL gets one more fix
  and verify; new MEDIUM/LOW rows are filed as OOS in the backlog. Gate samples: one fix round, then a known issue
  for delivery-014; safety samples block.
- Q146: parallel waves of up to 4 tasks in worktrees `.claude/worktrees/w003-tNNN`, cherry-picked, with the full
  suite once per wave.
- Q156: no Codex. The resync is committed alone; `/reload-skills`, run by the maintainer, replaces a new session.
- Never merge, and open no PR unless asked. Push only `work-003`. No model id in commit messages. Commits end
  with the `Co-Authored-By` and `Claude-Session` lines the session gives.
- Questions to the maintainer follow `.aid/runtime/templates/question-protocol.md`: one per message, recorded with
  `writeback-state.sh --ask` before it is shown and `--answer` after. The last question is Q173.

## Known failures (not this work's)

- Machine limits: `test-aid-dashboard-cli`, `test-aid-provisioning`, `test-kb-export`, `test-kb-html-claims-check`,
  `test-review-cost-meter`, `test-review-recall`, `test-settings-schema-check`, `test-summarize-preflight`,
  `test-visual-fidelity`.
- Under load only: `test-chat-node-federation` (passes alone).
- The repo is a shallow clone: "broken link" messages are normal.

## Commands

| Purpose | Command |
|---|---|
| Full suite | `HOME="$(mktemp -d)" bash tests/run-all.sh` |
| Site | `(cd site && npm run gen:skills && npm run gen:reference && npm run sync:docs)`, then `npx vitest run` |
| Resync | `python3 .claude/skills/generate-profile/scripts/run_generator.py` |
| KB index | `bash .aid/runtime/scripts/kb/build-kb-index.sh --root .aid/knowledge --output FILE` |
| Coverage | `bash tests/coverage-parity.sh collect --out FILE --allow-missing-runtime`, then `diff --baseline ... --after ... --allow tests/coverage-rehome-allowlist.tsv --accept tests/coverage-accepted-removals.tsv` |
| Cost | `python3 tests/cost-meter.py collect` / `diff` |
