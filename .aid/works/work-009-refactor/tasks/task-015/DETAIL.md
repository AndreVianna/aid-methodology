# task-015: Update the in-scope canonical shell suites to the YAML state format

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-015/STATE.md` -- this task's mutable cells live
only in the work-root state file's `### Tasks lifecycle` table.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** TEST

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-006, task-009

**Scope:**
- Update every IN-SCOPE shell suite the task-001 change-set enumerates, so each asserts the new
  filename and the new on-disk shape while asserting the SAME behavior it asserted before:
  `tests/canonical/test-writeback-state.sh` (Units 1-21, including Unit 8/17 concurrency, Unit 12
  isolation, and Unit 14's `|` rejection, which **inverts** under FR-4b and is therefore a
  change-set entry rather than a regression), `test-disjoint-merge.sh`,
  `test-delivery-gate-aggregate.sh`, `test-task-state-transitions.sh`,
  `test-pipeline-status-walkthrough.sh`,
  `test-delete-pipeline.sh` (the oracle for the `SPEC.md § L-10` `Running`-guard property, AC-13a /
  SP-19a -- see the added assertion below), `test-shortcut-engine-contract.sh`,
  `test-housekeep-workfolder-safety.sh`,
  `test-aid-migrate.sh`, `test-aid-migrate-trigger.sh`, `test-release-migrate-smoke.sh`, and
  `test-aid-cli-parity.sh` (the format-stamp twin pairing, now expecting 4).
- **`test-work-state-template.sh` is the heaviest entry here and must not be under-scoped**
  (`SPEC.md § L-9`). Its index runs **WS01-WS20**, of which **16 are live** (WS06, WS11, WS17,
  WS18 were removed as comment-text assertions). Two facts set the scope: (i) *most* assertions
  resolve their subject through `WORK_STATE` / `DELIVERY_STATE` / `TASK_STATE` (`:55-57`), pinned
  to `canonical/aid/templates/*-state-template.md` paths that FR-3 renames, so the whole file is
  a change-set entry at the path level (the exceptions resolve `DOGFOOD_WORK_STATE` (`:61`) or
  `FIRST_RUN` (`:62`), plus WS08, which resolves its subject inline via
  `find "$REPO_ROOT/profiles"` (`:167`) -- the `PROFILES_DIR` assignment (`:63`) is dead); and
  (ii) **eight** assertions break on content,
  not just on path: WS01 (`## Pipeline State` heading, `:66-71`), WS02's four bold-line field
  checks (`:81-86`), WS05's whole-line `active_skill:` assertion (`:126-129`),
  WS08 (the same heading in every rendered
  profile tree), and WS12
  (`## Cross-phase Q&A`), WS13 (`## Tasks State`), WS15 (`## Quick Check Findings`), WS16
  (`## Dispatch Log`) against `delivery-state-template` / `task-state-template`. Each is
  retargeted to the `.yml` shape and recorded as an intended change-set entry, never left to look
  like a regression. WS02's three frontmatter-key checks (`:88-93`) and
  WS03/WS04/WS10/WS14 survive in substance (enum members, mutable-cell keys --
  D-2 preserves both byte-for-byte) but move to the renamed file; WS05 splits across both
  classes -- its bare-substring assertion (`:122-125`) survives inside a comment, while its
  whole-line assertion (`:126-129`) is a content break; WS07 changes only the dogfood
  path it resolves (`:61`); WS09's two negative `Status` greps (`:185-199`) still pass against a
  heading-less `.yml`; WS19/WS20 change only where the
  `aid-describe` seed prose names the retired markdown fields.
- **Four further template-referencing suites, same class** (`SPEC.md § L-9`; found by `grep -rl`
  for the three template names under `tests/`) -- they were missing from earlier drafts of the
  in-scope list and are in scope here: `test-connector-consumption-linkage.sh` (CL08c-e assert
  `ticket_ref` in all three `*-state-template.md` files, paths at `:60-62`),
  `test-ticket-retirement-structural.sh` (T087-T089, the same three paths, `:93-95`),
  `test-cutover-no-dangling.sh` (CND12a-b resolve `work-state-template.md` and assert the absence
  of two `##` headings, `:124-130`), and `test-describe-full-only.sh` (`:233+` builds a markdown
  work-state fixture carrying `## Pipeline State` / `## Interview State`, the shape FR-2b retires).
  Every assertion changed in these four is recorded against a change-set entry like any other --
  an unlisted suite that regresses is indistinguishable from one intentionally updated (SP-16).
- Add the assertions the new surfaces need in these suites' own idiom: the conversion step's
  idempotence and its DERIVED-row hard error (`test-aid-migrate.sh`), the writer's single-line-diff
  property and its `|`/newline/colon/quote round-trip (`test-writeback-state.sh`), the
  `enumerate-works.sh` / `cleanup-classify.sh` sentinel degradation, and -- in
  `test-delete-pipeline.sh` -- the task-006 `Running`-guard property asserted **behaviorally**
  against a converted `STATE.yml` (exit 7), because a half-retargeted guard is a silent no-op that
  no textual assertion can catch (SP-19a, `SPEC.md § L-10`).
- **Must not be edited** (editing one is itself a scope defect): `test-discover-preflight.sh`,
  `test-summarize-preflight.sh`, `test-kb-freshness-check.sh`, `test-grade-summary.sh`,
  `test-kb-review-surface.sh` (discovery ledger only), plus `test-migrate-hierarchy.sh` and
  `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/`, triaged OUT by
  `SPEC.md § L-6` -- their 89 assertions stay untouched and keep proving the era migration works.
- Every changed assertion is recorded against the task-001 change-set entry it implements, so
  task-019 can distinguish an intended update from a regression.
- OUT of this task: the dashboard/reader suites (task-016); the new review-surface suite
  (task-013); the conformance corpus and cross-format suite (task-005, task-011);
  `tests/coverage-baseline.tsv` (re-bootstrapped in task-019).

**Acceptance Criteria:**
- [ ] Every in-scope shell suite named in Scope passes, per its own summary line, under
      `HOME="$(mktemp -d)" bash tests/run-all.sh` (SP-16, `test-landscape.md § Test Commands`).
- [ ] Every assertion changed corresponds to an entry in the task-001 change-set; any change NOT on
      that list is added to it with a stated reason before this task closes (SP-16).
- [ ] Unit 14 of `test-writeback-state.sh` now asserts that a `|`-bearing value round-trips intact,
      and the inversion is recorded in the change-set as intended (SP-5, FR-4b).
- [ ] `test-writeback-state.sh` asserts the single-line-diff property, the exit-code contract
      0/1/2/3/4/5/6, exit 4 on an out-of-enum value, exit 6 on a malformed file, and CRLF /
      no-trailing-newline round-trips (SP-4, SP-5, SP-6).
- [ ] `test-disjoint-merge.sh` still models N parallel writers and now asserts the file parses at
      every observable moment with no silently-lost write (SP-6).
- [ ] Every live assertion in `test-work-state-template.sh` (the 16 of WS01-WS20 that are not
      removed) resolves the renamed `.yml` template paths and asserts the `.yml` templates' shape,
      including that no writer-owned key carries a trailing inline comment and that no
      un-instantiated placeholder sits on a key whose value must be readable before the first
      write, and that no DERIVED key exists (SP-20, SP-2, SP-3).
- [ ] Each of the eight content-breaking assertions -- WS01, WS02's four bold-line
      field checks, WS05's whole-line `active_skill:` assertion, WS08, WS12, WS13, WS15, WS16 -- is
      retargeted and recorded as an enumerated change-set entry, not a regression (SP-16, FR-2b,
      FR-3).
- [ ] The four further template-referencing suites --
      `test-connector-consumption-linkage.sh` (CL08c-e), `test-ticket-retirement-structural.sh`
      (T087-T089), `test-cutover-no-dangling.sh` (CND12a-b) and `test-describe-full-only.sh`
      (its markdown work-state fixture) -- pass against the renamed templates, with each changed
      assertion recorded against a change-set entry (SP-16, FR-3).
- [ ] `test-delete-pipeline.sh` asserts the SP-19a guard property behaviorally: against a converted
      work whose `STATE.yml` carries `lifecycle: Running` the script exits 7, and against a work
      with no state file it behaves exactly as pre-refactor (the carried fail-open, `SPEC.md § L-12`)
      -- so a half-retargeted `delete-pipeline.sh` fails this suite instead of passing silently
      (SP-19a, FR-7a).
- [ ] `test-aid-migrate.sh` asserts the conversion step's idempotence, its DERIVED-row hard error,
      and the stamp advancing to 4; `test-aid-cli-parity.sh` asserts the Bash/PowerShell stamp
      pairing at 4 (SP-12).
- [ ] The five discovery-ledger-only suites, `test-migrate-hierarchy.sh` and the
      `work-999-migration-test` fixture tree are byte-unchanged (`git diff` shows no entry for
      them).
- [ ] Every suite stays hermetic and deterministic: pinned `HOME` (and `USERPROFILE` where a suite
      invokes `bin/aid.ps1`), own temp dir, no network, cleanup on exit
      (`task-type-rules.md § TEST`).
- [ ] All section-6 quality gates pass.
