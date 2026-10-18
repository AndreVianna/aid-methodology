# task-370: Conversation runner fixes from the independent review (h001)

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 370 --field State.

**Type:** FIX

**Source:** feature-001-plain-language-requests -> delivery-001 -> NFR-T (gate fix; `analysis/delivery-001-review-codex.md` rows 1-4)

**Depends on:** task-369

**Scope:**
- `tests/conversation/run.py`, the four findings of `analysis/delivery-001-review-codex.md`:
  1. `ledger_status`: split a table row on unescaped `|` only, so a cell holding the schema's escaped
     pipe `\|` stays one cell and its row still counts. A Pending row with `\|` in any cell counts.
  2. `diff_chunks`: a file added or deleted with empty content still yields a diff entry, in the
     shape of git's own (`new file` / `deleted file` header with no hunk), so `files.diff` records it.
  3. `segment_is_git_push`: also detect `git push` behind a shell's combined flags holding `c`
     (`bash -lc`, `sh -ec`, ...) and behind the `env`, `command`, `exec`, `nohup` and `sudo` wrappers,
     including `env`'s own `VAR=value` operands and `-i` / `-u NAME` options.
  4. `snapshot`: record every symbolic link inside the fixture and the throwaway `HOME` as an entry
     whose content is its link target (prefixed so it never equals a regular file's bytes), and do not
     follow it, so a link created, removed or retargeted shows in `files.diff`. A link's target is
     never read through.
- `tests/canonical/test-conversation-runner.sh`: one case per fix, each failing against the unfixed
  function (a throwaway copy of `run.py` with that one fix reverted), as the suite's other mutation
  cases do.
- Re-score the delivery-001 gate's 48 sample runs with the fixed `ledger_status`, from their saved
  `ledger.md` files under `.aid/.temp/conversation-tests/`, and update
  `analysis/delivery-001-gate.md` and KI-007 in `known-issues.md` if any verdict changes.
- **Test step:** `python3 -m py_compile tests/conversation/run.py`; `bash -n` on the suite; then
  `HOME="$(mktemp -d)" bash tests/canonical/test-conversation-runner.sh` and
  `HOME="$(mktemp -d)" bash tests/canonical/test-conversation-suite.sh` if present. `tests/` is not
  resync-relevant (PLAN.md The resync rule), so no resync follows.

**Acceptance Criteria:**
- [ ] `ledger_status` counts a seven-column Pending row whose Evidence holds `\|` as one Pending row.
- [ ] `build_diff({}, {'fixture/empty.md': b''})` and its reverse are not empty and name the file.
- [ ] `is_git_push` is true for `bash -lc "git push origin main"`, `env GIT_TERMINAL_PROMPT=0 git push`,
      `command git push` and `sudo git push`, and still false for `echo git push` and a heredoc naming it.
- [ ] A new, removed or retargeted symbolic link in the fixture appears in `files.diff`; a link is never
      followed.
- [ ] `test-conversation-runner.sh` has one passing case per fix, each failing its own mutation; every
      existing case still passes.
- [ ] The gate's 48 runs are re-scored, and the gate report and KI-007 match the new counts.
