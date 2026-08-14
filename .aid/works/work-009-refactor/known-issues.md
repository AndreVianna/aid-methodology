# Known Issues

<!-- Scoped to this work. Only issues that affect features in this work. -->
<!-- Created/updated by aid-specify during codebase exploration. -->
<!-- Consumed by aid-plan for deliverable sequencing. -->

<!-- Entry format:
## KI-NNN: {Title}
- **Type:** Bug | Security | Deprecated Dependency | Breaking API Contract
- **Severity:** Critical | High | Medium
- **Affects:** feature-NNN-{name}, feature-NNN-{name}
- **Source:** {file path}:{line} or {dependency}:{version}
- **Description:** {what's wrong and why it matters for the affected features}
- **See also:** tech-debt.md #TD-NNN (if already catalogued in KB)
-->

## KI-001: `writeback-state.sh --findings` has no flattened-layout branch, and its findings home contradicts the documented one

- **Type:** Bug
- **Severity:** High
- **Affects:** feature-001
- **Source:** `.claude/aid/scripts/execute/writeback-state.sh:1030` (`mode_findings`)
- **Description:** Two coupled defects in the same function, both found while running
  this work's own task-001 REVIEW.

  **(a) No flattened-layout branch.** `mode_field` guards its path resolution with
  `is_flat_layout` (line 796) and diverts to `write_task_field_flat`, which writes the
  work-root `STATE.md § ### Tasks lifecycle` row. `mode_findings` has no such guard: it
  calls `resolve_delivery_for_task_mode` + `resolve_task_state_file` unconditionally
  (lines 1035-1036) and so resolves
  `deliveries/delivery-001/tasks/task-001/STATE.md` — a path that by definition does
  not exist on a flattened work, where tasks are `tasks/task-NNN/DETAIL.md` only. The
  call dies with exit 1. Since
  `aid-execute/references/state-review.md § Write Findings to STATE.md` mandates
  `writeback-state.sh --task-id NNN --findings "BLOCK"` at every task's REVIEW, this
  blocks the mandated write for **all 20 tasks** of this work, not just one.

  **(b) The findings home disagrees with the documentation.** The implementation
  writes an *unkeyed* `## Quick Check Findings` section into the *per-task* `STATE.md`,
  replacing the whole section body on each call — justified by the comment at line
  1049 ("the task owns this file exclusively, so there is no per-task sub-heading
  needed"). Three docs say otherwise: `state-review.md:145-147` ("writes/replaces the
  `### task-NNN` block under `## Quick Check Findings` in the work `STATE.md`, keyed by
  task-id, single-writer per task by construction — safe under FR6 parallel
  execution"), and `.claude/aid/templates/delivery-issues.md:11,42` (both cite
  `work-NNN/STATE.md ## Quick Check Findings`). So even the `AID_TASK_STATE_FILE`
  override is not a usable workaround on a flattened work: pointing it at the work-root
  `STATE.md` would make each task's findings overwrite the previous task's, precisely
  the collision the documented `### task-NNN` keying exists to prevent. Compounding
  this, `work-state-template.md` defines **no** `## Quick Check Findings` section at
  all, so the flattened layout has no declared home for the block in either place.

  Consequence: on a flattened work, per-task quick-check findings cannot be recorded
  through the supported interface. For task-001 the outcome was "no CRITICAL/HIGH", so
  nothing substantive was lost — it was recorded in the task row's `Notes` cell
  instead — but a task that produced a `[HIGH]` finding would lose the record of it,
  and `[HIGH]` findings are the input the per-delivery gate aggregates.

  **Orthogonal to this work's premise, but inside its edit surface.** The bug predates
  the refactor and is not caused by the STATE.md → STATE.yml conversion. It lands in
  scope only because this work already rewrites both affected files: task-007 collapses
  `writeback-state.sh` onto one YAML single-key write path, and task-002 converts the
  three work-tree state templates. Fix it there rather than as a separate patch, so the
  fix is written once against the YAML shape instead of twice.
- **See also:** not catalogued in `tech-debt.md`

## KI-002: AC-6/SP-10's "no stat is added" and AC-5/SP-9's legacy detection cannot both be met literally

- **Type:** Breaking API Contract
- **Severity:** Medium
- **Affects:** feature-001
- **Source:** `dashboard/reader/reader.py` (legacy-`STATE.md` detection guard), task-003 AC-5 vs AC-6
- **Description:** task-003's AC-6 requires that "no stat or glob is added" (SP-10, the read-cost
  containment property). Its AC-5 requires that a work directory holding a `STATE.md` with no
  sibling `STATE.yml` yields `_minimal_work_model` plus a `parse_warning` naming the migration
  command (SP-9). Detecting "the legacy file is present AND the new one is not" needs at least one
  filesystem probe that the pre-refactor reader did not perform, so the two criteria are in direct
  tension as written.

  The executor resolved it by adding **exactly one** `.is_file()` call, computing `state_exists`
  once and reusing it for both the legacy check and the monolithic branch's own presence check, and
  disclosed the deviation rather than claiming AC-6 passed. That is the right disclosure behavior
  and the cost is negligible next to the file read itself.

  **A viable alternative was not taken**, and the delivery gate should rule on whether to require
  it: EAFP instead of LBYL — attempt the `STATE.yml` read, and on `FileNotFoundError` attempt
  `STATE.md`. That reaches the same outcome with no added stat, since the read path already stats
  for its `MAX_READ_BYTES` size check (`io_bounds.py:13-16`). The cost of the alternative is
  exception-driven control flow on the reader's hot path, which is why it is a judgment call rather
  than an obvious win.

  **This binds task-004.** The Node twin is specified as a function-for-function *port* of task-003
  (NFR-1, C-4) so that parity is structural rather than re-derived. Whichever way this resolves,
  both twins must do the same thing — if the Python twin keeps the extra stat and the Node twin uses
  EAFP, the twins diverge on observable read cost and on the number of filesystem operations per
  work, which is exactly what task-005's conformance corpus and task-011's cross-runtime suite exist
  to catch. Decide before task-004 executes, or accept the stat in both.

  **Ruling applied (orchestrator, pending delivery-gate confirmation):** keep the single
  `.is_file()` in BOTH twins and treat AC-6 as amended rather than violated. Grounds: the read path
  already stats for its `MAX_READ_BYTES` size check, so the marginal cost is nil; AC-5's legacy
  detection is user-facing (it is what tells someone to run `aid update` instead of silently
  presenting an empty work); and EAFP would put exception-driven control flow on the reader's hot
  path for no measurable gain. AC-6's purpose is keeping dashboard read cost flat, and one stat per
  work does not threaten it. The gate may overturn this; it is recorded here rather than buried in
  a commit message precisely because it is a spec-tension ruling.
- **See also:** not catalogued in `tech-debt.md`

## KI-003: `ticket_ref` is declared in the state template but parsed by neither reader twin

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-001
- **Source:** `canonical/aid/templates/work-state-template.yml` (`ticket_ref` key); `dashboard/reader/parsers.py`; `dashboard/server/reader.mjs`
- **Description:** The work-level state template declares an optional `ticket_ref` scalar
  (`<connector-stem>:<external-id>`, e.g. `jira:PROJ-123`) linking a work to an external tracker
  item. Surfaced during task-003's review: **neither reader parses it** — not the new structured
  parser, and not the pre-refactor markdown one either. So the field round-trips on disk and is
  written by the writer, but never reaches the model or the dashboard.

  **Pre-existing, not a task-003 regression** — verified against the pre-refactor `parsers.py`. It
  therefore falls under `SPEC.md § L-12` (pre-existing staleness preserved, not repaired): repairing
  it inside this work would be an observable behavior change a `restructure` forbids, and it is not
  in any task's scope.

  **Relevance to task-004:** the Node twin must NOT start parsing it either. A port that "helpfully"
  adds `ticket_ref` support would make the twins diverge on model contents, failing task-005's
  conformance corpus and task-011's cross-runtime parity suite — and would be an out-of-scope
  behavior change on top. Symmetry in the omission is the requirement.

  Genuine follow-up work for a later work item, not this one: either wire the field through both
  readers or drop it from the template. Right now it is a declared field with no consumer.
- **See also:** not catalogued in `tech-debt.md`

## KI-004: the coarse-`updated` fallback is dead on the Python side, and the twins now diverge on it

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-001
- **Source:** `dashboard/reader/derivation.py:905` (`_extract_latest_history_date`), called at `:722`,
  `:735`, `:753`, `:771`, `:783`; vs `dashboard/server/reader.mjs` (`computeLatestHistoryDate`)
- **Description:** `derive_lifecycle`'s coarse-`updated` fallback scans for a markdown
  `## Lifecycle History` **table**. After the conversion there is no such table — `lifecycle_history`
  is a YAML list — so the scan is dead code against every `STATE.yml`. Measured directly:

  ```
  _extract_latest_history_date(STATE.yml shape) -> None          <- information lost
  _extract_latest_history_date(markdown shape)  -> '2026-08-12'  <- what it used to find
  ```

  Two distinct problems follow, and they should not be conflated.

  **(a) A behavior change on the Python side that a `restructure` is supposed to forbid.** Before the
  conversion, a work lacking an authoritative `updated` still got a coarse date from its history
  table. It no longer does. This is not task-003's defect — `derivation.py` is explicitly outside
  the edit scope of both task-003 and task-004, so *no task in this delivery owns the fix.* That is
  the gap: the file is out of scope for everyone, yet the refactor silently invalidated five of its
  call sites.

  **(b) The first genuine twin-parity divergence.** task-004 had no equivalent module boundary in
  `reader.mjs`, so it replaced the dead scan with `computeLatestHistoryDate()` =
  `max(lifecycle_history[].date)` over the already-parsed array. That is the *better* behavior — but
  it means Node derives a date where Python derives `None` for the same input.

  **Trigger is narrow but constructible**, which is exactly why it must be written down rather than
  left to be rediscovered: it needs `lifecycle` absent or invalid **and** `updated` absent (the scan
  is consulted only when there is no authoritative `Updated`) **and** `lifecycle_history` present
  with real dates. A fixture with an explicit `updated:` does **not** trigger it — verified, which is
  why task-004's own 6-work reader-level parity comparison came back identical and did not catch
  this. Absence of a parity failure in that comparison is not evidence of parity here.

  **Bears directly on task-011** (cross-format, cross-runtime characterization). Its corpus must
  include this exact three-condition case, or the divergence ships. It will otherwise look like
  parity holds, for the same reason task-004's harness did.

  **Needs a scope decision, not a silent choice.** Three options: (i) bring the five `derivation.py`
  call sites into scope for a follow-up task and thread the structured value through, matching Node;
  (ii) accept the Python fallback as permanently dead and make Node match it by *removing*
  `computeLatestHistoryDate`, restoring parity at the cost of the better behavior; (iii) accept the
  divergence and encode it as an expected difference in task-011's corpus. (i) is the honest fix,
  (ii) is the cheapest way to restore parity, (iii) is the one that should not happen by default.

  **RESOLVED (task-021): option (i) taken.** `dashboard/reader/parsers.py`'s `parse_state_md` now
  reads `lifecycle_history` once (moved earlier, still the same single read) and computes
  `latest_history_date` via a new `_compute_latest_history_date()` helper -- `max` over the
  ALREADY-parsed sequence's `date` values, skipping non-dict entries, non-string `date` values, and
  null-sentinel (`--`) dates -- the exact twin of `reader.mjs`'s `computeLatestHistoryDate()`. That
  value is threaded into `derivation.py`'s `derive_lifecycle()` as a new `latest_history_date`
  keyword parameter; all five priority branches now return it verbatim instead of each calling the
  now-deleted `_extract_latest_history_date(state_text)` (and its `_RE_DATE` regex, deleted with it --
  `_RE_HISTORY_SECTION` survives, `_has_cancellation_in_history` is still a consumer). No second file
  read, no added stat or glob (SP-10 unaffected). Verified: for the exact three-condition fixture this
  entry describes, Python now derives `'2026-08-12'` where it previously derived `None`, matching
  `reader.mjs` on the same fixture; a `read_repo` diff over a 4-work fixture (two authoritative-
  `lifecycle`, one authoritative-`updated`-only, one triggering the fallback) shows the coarse-
  `updated` value change ONLY on the fallback-triggering work -- every authoritative-input work is
  byte-identical before/after, and `bytes_read` is unchanged (no added read).
- **See also:** not catalogued in `tech-debt.md`

## KI-005: quick-check findings are now stored in two different shapes, one per layout

- **Type:** Breaking API Contract
- **Severity:** Medium
- **Affects:** feature-001
- **Source:** `canonical/aid/scripts/execute/writeback-state.sh` (`mode_findings`, flattened branch)
- **Description:** task-007 did NOT port the merged upstream fix's `### task-NNN` markdown sub-block
  for `--findings` -- that shape cannot survive a YAML conversion. It re-homed the write as
  `tasks_lifecycle.task-NNN.quick_check`, **a single scalar holding the raw findings block verbatim**
  (D-5 mode-3 escaped). Verified working against a real flat work:

  ```
  quick_check: "- **Reviewer Tier:** Small\n- **Findings:** none"
  ```

  The executor's reasoning is sound and worth preserving: `§ D-3`'s nesting cap (a sequence at the
  second level) makes a *sequence*-shaped `quick_check.findings` under `tasks_lifecycle.task-NNN`
  structurally illegal -- it would be a third mapping level plus a sequence -- and the already-shipped
  `work-state-template.yml` declares no top-level `quick_check` key for the flat layout, which
  confirms `§ D-4`'s "inventing a work-level quick_check key is out of scope" note describes a real
  capacity limit rather than a convenience call.

  **The consequence the gate should rule on:** the two layouts now store findings in different shapes.
  A full-layout per-task file gets the structured `quick_check.findings` sequence `§ D-4` declares; a
  flattened work gets one opaque escaped scalar. On the flat path findings therefore cannot be
  decomposed into per-entry severity / description / source / disposition records -- which is exactly
  what the per-delivery gate aggregates when it collects deferred `[HIGH]` rows.

  Not obviously wrong: the readers' `parse_quick_check_findings` already returns empty for a
  current-shape work, and `§ L-12` requires preserving that staleness rather than repairing it, so
  nothing regresses today. But it does mean the flat layout's findings are written and never read, and
  the asymmetry is now deliberate in the writer rather than incidental.

  **Binds task-011 and task-016:** any cross-layout assertion must expect two shapes, not one. If the
  gate wants a single shape, the fix is a schema change in `§ D-4` plus `work-state-template.yml` --
  a task-002 amendment, not a writer patch.
- **See also:** not catalogued in `tech-debt.md`

## KI-010: `wb_get_kv`'s seq verify died at exit 3 on every non-empty sequence write -- FIXED by task-015

- **Type:** Bug
- **Severity:** Critical
- **Affects:** feature-001
- **Source:** `canonical/aid/scripts/execute/writeback-state.sh` (`WB_GET_KV_AWK`, the
  `n==2 && l0 && $0 ~ /^[A-Za-z0-9_-]+:/ && status=="notfound"` rule); identically forked into
  `dashboard/scripts/writeback-state.sh`
- **Description:** Discovered while building this task's test oracle (test-writeback-state.sh), NOT a
  test-format issue -- a genuine, 100%-reproducible defect in the already-shipped task-007 writer,
  confirmed against the real `task-state-template.yml` / `delivery-state-template.yml` shapes (not
  just a hand-rolled fixture). Root cause: the read-back sanity check `wb_get_kv` walks a written
  sequence's `- ` continuation lines via a `collecting` flag, but the earlier, unguarded
  "next top-level key means NOTFOUND" rule fires on that SAME boundary line first (program order) and
  calls `exit` before the `collecting` rule gets a chance to finalize the count -- printing a spurious
  `NOTFOUND`. Because that rule never sets `status="found"`, the `END` block then ALSO fires and prints
  the correct `SEQ|n|first` line, so `wb_get_kv` emits TWO lines from one call and `wb_state_verify`'s
  exact-string compare can never match either one. Every `--findings` write with a non-empty findings
  list (`quick_check.findings`) and every `--block` write with a non-empty issue list
  (`delivery_gate.issue_list`) therefore died at exit 3 -- discarding the correctly-computed temp file
  and leaving the original untouched -- whenever the written key was followed by ANY sibling top-level
  key, which is the ordinary case in both shipped templates (`quick_check` is always followed by
  `dispatch_log`; `delivery_gate` is always followed by `qa`). The write path (`WB_SET_KV_AWK`) was
  never wrong; only this verify-and-die guard was. Empty-sequence writes (`findings: []` /
  `issue_list: []`, matched inline before `collecting` is ever set) were unaffected, which is why
  task-007's own verification ("flat --findings survives") did not catch it -- the flattened branch
  writes `quick_check` as one scalar, never hitting this code path at all; only the FULL-layout
  structured `quick_check.findings` / `delivery_gate.issue_list` writes are affected.
- **Fix:** one-condition guard added to the offending rule (`&& !collecting`), so a top-level sibling
  key encountered mid-sequence now falls through to the `collecting` rule's own boundary handling
  instead of pre-empting it. Verified via direct script invocation (not just the eventual test suite)
  against both real templates: non-empty single-item, multi-item, shrink-on-overwrite, and
  empty-again all round-trip correctly post-fix; the genuinely-absent-key `NOTFOUND` path is unchanged
  (regression-checked). Applied to both the canonical script and the dashboard fork (identical code,
  independently forked, not covered by the profile-render sync); profiles/ regenerated via the FULL
  `run_generator.py` and the `.claude/` / `.cursor/` dogfood trees resynced for this one file.
- **See also:** not catalogued in `tech-debt.md` yet -- task-019 should confirm this closes clean and,
  if so, this KI (like the others) is deleted with the work folder rather than migrated there.

## KI-011: several already-shipped canonical/bash test suites hardcode a stale `format_version: 3` -- one is now inverted (asserts the opposite of its own name)

- **Type:** Bug
- **Severity:** High (one instance is not merely stale text but an inverted assertion)
- **Affects:** feature-011 (`bin/aid` / `bin/aid.ps1` migration engine), test suite only -- no
  production code is affected by this KI (that engine's `AID_SUPPORTED_FORMAT` bump to 4 is
  task-008's own, already-shipped and correct, change)
- **Source:** `bin/aid:121` `readonly AID_SUPPORTED_FORMAT=4` / `bin/aid.ps1:162`
  `Set-Variable -Name AidSupportedFormat -Value 4` (task-008, prior to this task). Discovered while
  extending `test-aid-migrate.sh` for task-015's new conversion-step gate (Gate 15) and while auditing
  the other three in-scope suites this task's DETAIL.md names for the same reason
  (`test-aid-migrate-trigger.sh`, `test-release-migrate-smoke.sh`, `test-aid-cli-parity.sh`).
- **Description:** task-008 bumped `AID_SUPPORTED_FORMAT` from 3 to 4 (a genuinely new format
  version, for the STATE.md -> STATE.yml conversion this same task added) but left every test suite
  written against the OLD value of 3 untouched. Two distinct failure shapes resulted:
  (a) **stale-but-harmless** -- assertions that check the migration tool stamps `format_version: 3`
  (`test-aid-migrate.sh` G4A-02; `test-aid-migrate-trigger.sh` TRG-MO02/TRG-F01/TRG-J02;
  `test-release-migrate-smoke.sh` `assert_migrated`'s `-B` check; `test-aid-cli-parity.sh` PAR077-C02,
  PAR009-V01c/V01d) -- these simply expect a value the writer no longer produces, so they were
  outright failing (or would fail once run), not silently wrong.
  (b) **inverted** (worse) -- `test-aid-cli-parity.sh`'s PAR080-S03/S04 ("format-current repo ->
  no WARN") and PAR009-V02-V06/PAR029-W11-W15 ("refuse-on-newer") fixtures both hardcoded
  `format_version: 4` as their probe value. While supported was 3, that value correctly meant
  "one version newer than supported" for the refuse-path tests, and (separately) the
  format-current fixture used 3. Now that supported IS 4, the refuse-path fixtures' `4` means
  "current" (would no longer refuse -- the opposite of what those tests assert), and (independently)
  the format-current fixture's old value of 3 would now WARN (one version stale) instead of staying
  silent. Both would have produced exactly-wrong-signal failures (a refuse-path test that now expects
  a refuse that no longer happens; a silent-path test that now expects silence that no longer holds)
  had they been run against the current binaries before this fix -- not a cosmetic staleness, an
  inverted oracle.
- **Fix (this task, in-scope files only):** every in-scope-suite instance retargeted from `3`/`4` to
  the correct current values (`format_version: 4` for "current/just-migrated", `format_version: 5`
  for "one newer than supported"), each verified either by direct probe against real `bin/aid` (Gate
  15's fixtures) or by re-reading `_aid_format_gate`'s 3-way classify logic (`bin/aid:1992-2012`)
  line-by-line against the fixture value before editing (PAR080/PAR009/PAR029). `test-aid-cli-parity.sh`
  PAR077-C08 was additionally promoted from an unconditional `pass()` stub to a real PWSH invocation,
  since `bin/aid.ps1` now carries its own `Sc-ConvertRepo` / `$AidSupportedFormat=4` twin (it did not
  when the stub was written) -- covered per AC-10's explicit "Bash/PowerShell stamp pairing at 4."
- **NOT fixed (explicitly out of task-015's scope, flagged here for follow-up):** the identical bug
  class (a) also exists in suites this task was NOT assigned to touch --
  `tests/canonical/test-registry.sh` (`REG-P03b-04b`, `REG-V06b`, `REG-V06c`),
  `tests/canonical/test-install-provisioning.sh` (`SE1e`), `tests/windows/Test-InstallProvisioning.ps1`
  (`SE1d`/`SE1e`), `tests/windows/Test-AidInstaller.ps1` (`T48c`). Each of these directly asserts a
  migration-tool-produced `format_version: 3` value the same way `test-aid-migrate.sh` G4A-02 did --
  editing them was out of this task's enumerated Scope (DETAIL.md names 17 specific suites; these four
  are not among them), and per SPEC's own scope discipline, expanding into unlisted files is itself a
  scope defect. `tests/canonical/test-graph-runtime*.sh`, `test-graph-source-enumeration.sh`, and
  `test-read-setting.sh` also contain literal `format_version: 3` strings but are NOT instances of this
  bug -- they write it as arbitrary, unrelated fixture content for testing graph-rule / read-setting
  logic that does not care what the number is, not as an assertion against the migration tool's own
  output.
- **See also:** not catalogued in `tech-debt.md` yet -- the four out-of-scope files above should be
  raised as a follow-up task (or added to `tech-debt.md` directly) so their real, currently-latent
  failures are fixed before they surface as a surprise in CI.

## KI-006: several pipeline write-targets have no home in the YAML schema (surfaced by task-014)

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-001
- **Source:** `canonical/aid/templates/work-state-template.yml` (schema, task-002); various recipes
  retargeted by task-014
- **Description:** Retargeting every recipe from markdown-section language to key language forced the
  question "which key does this write land in?" for each one, and four writes turned out to have **no
  key to name** in the converted schema. task-014 documented each honestly (the recipe now says the
  write has no persisted target / the console line is the sole record) rather than pointing prose at a
  nonexistent key. Pre-existing design gaps the conversion exposed, not defects task-014 introduced:

  1. **Non-task-scoped dispatches have no persisted Calibration Log target.** `## Calibration Log` /
     `## Dispatches` are DERIVED solely from per-task `dispatch_log` entries. A dispatch that is not
     task-scoped -- a document-level shortcut-engine dispatch, the generic
     `dispatch-protocol-checklist.md` / `long-wait-protocol.md` usage, aid-discover / aid-housekeep /
     aid-monitor's own dispatches, pool dispatch's PD-0 probe -- has nowhere to be recorded. (This
     work hit it directly: its own Calibration Log rows are authored by hand into the markdown body,
     which is exactly why the task-008 DERIVED guard refuses to auto-convert this work's STATE.md.)
  2. **`## Seed Authoring`** (aid-describe DESCRIBE-SEED) has no key in any of the three templates,
     old design or new.
  3. **The reviewer "Review History" list** (aid-define, aid-specify) has no key.
  4. **The `deploy` key shape** (per-delivery records) does not match aid-deploy's actual
     Status / Active-Package / History state-machine tracking, and a full multi-delivery work has no
     work-level `qa` key for aid-ask / aid-specify to target before any delivery exists.

  Nothing regresses today -- these sections were markdown body that no reader parsed into the model,
  and `§ L-12` preserves that. But the conversion has now made the gaps explicit: recipes that used to
  say "append to `## Seed Authoring`" now have to admit there is no target. The honest fix for each is
  a `§ D-4` schema decision (add the key, or formally retire the section), i.e. a task-002 amendment
  scoped by the gate -- not something a DOCUMENT or writer task can resolve on its own.
- **See also:** not catalogued in `tech-debt.md`

## KI-007: the vendored copies under packages/ are stale and no task in this delivery re-syncs them

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-001
- **Source:** `packages/npm/dashboard/home.html`, `packages/pypi/aid_installer/_vendor/dashboard/home.html`,
  and the `packages/**` vendored copies of `bin/aid` / `lib/aid-install-core.sh`
- **Description:** `packages/` carries vendored copies of files this delivery changed at their real
  home, and nothing in the delivery re-derives them. Confirmed from three independent tasks:
  - task-009: the vendored `bin/aid` / `lib/aid-install-core.sh` under `packages/npm` and
    `packages/pypi/.../_vendor` still declare `AID_SUPPORTED_FORMAT=3`.
  - task-014 + task-020: the vendored `dashboard/home.html` copies still say `STATE.md` after the
    canonical one was converted.
  - task-017: the render generator (`generate-profile`) has **no reference to `packages/npm` or
    `_vendor`** (grep-confirmed), and the dogfood resync only touches `.claude/` / `.cursor/`. So the
    render fan-out provably does not cover `packages/`.

  These are re-vendored by a **release-time** step (`vendor.js` / `vendor.py`, per the `.gitattributes`
  note), not by any per-work task. So within this delivery they are correctly left stale.

  **Consequence if the release-time re-vendor does not run before shipping:** an adopter installing via
  npm or pypi gets a format-3 `bin/aid` against format-4 canonical, and a dashboard UI labelling
  `STATE.yml` files as `STATE.md`. The gate must confirm the release pipeline re-vendors `packages/`
  from source (bin/, lib/, dashboard/) as part of the cut, or this becomes shipped drift. This is not a
  task to run here (editing a vendored copy by hand would defeat the point of a re-derivable vendor
  step); it is a release-checklist item to verify.
- **See also:** not catalogued in `tech-debt.md`

## KI-008: task-017 installed the YAML-only writer before task-010 converts this work -- own tracking now needs conversion

- **Type:** Bug
- **Severity:** High
- **Affects:** feature-001 (this work's own live tracking; the ordering rule generally)
- **Source:** `.claude/aid/scripts/execute/writeback-state.sh` (post-task-017 resync) vs
  `.aid/works/work-009-refactor/STATE.md` (still markdown)
- **Description:** The 017-before-010 sequencing gap, predicted before wave 7 and now live.
  task-017's dogfood resync replaced the installed `.claude/` writer with task-007's YAML-only
  version, whose new malformed-file check (`wb_state_is_mapping`) rejects a markdown state file with
  exit 6. This work's OWN `STATE.md` is still markdown (task-010 has not run), so
  `writeback-state.sh` can no longer write this work's tracking file:

  ```
  ERROR: writeback-state.sh: malformed STATE.yml: .../work-009-refactor/STATE.md does not parse as
  a YAML mapping (exit 6)
  ```

  From task-017 onward, task states for THIS work are recorded by direct markdown edit (the
  documented fallback) until the work's own `STATE.md` is converted to `STATE.yml`.

  **The remedy is task-010, and it is now on the critical path** for continued tracking, not merely a
  cleanup step. Scoped to this worktree per the owner's hard rule, task-010 converts exactly one
  work: this one. **A wrinkle the gate must decide:** task-008's converter refuses a work whose
  DERIVED section holds real rows, and this work's `## Calibration Log` is hand-authored with real
  dispatch rows (a flattened work has no per-task `dispatch_log` to derive them from -- the KI-006
  gap, hit against this very work). So an automatic `aid update` conversion of this work will trip the
  DERIVED guard. Converting it needs an explicit decision on those Calibration Log rows: drop them
  (they are a DERIVED view with no persisted source), or preserve them by hand into a
  non-DERIVED home.

  **General lesson for the ordering rule:** the render fan-out (which installs the new writer into
  `.claude/`) must not run before the live-work conversion when the pipeline dogfoods its own writer
  on an in-flight work. For a normal adopter this never bites (they are not mid-work on the AID repo
  itself); for this self-hosting delivery it does.
- **See also:** not catalogued in `tech-debt.md`

## KI-009: full-layout work-level `## Cross-phase Q&A` (work-owner-authored channel) has no YAML home -- blocks conversion of any full work that uses it

- **Type:** Design gap (specialization of KI-006)
- **Severity:** High
- **Affects:** the converter (task-008) + the full-layout target shape (SPEC.md D-2/D-4, line ~361);
  surfaced live by `work-005-knowledge-graph` during task-010.
- **Source:** `bin/aid` `_aid_sc_convert_work_body` (full layout does NOT call `_aid_sc_emit_qa`
  and guards `## Cross-phase Q&A` as DERIVED-narrative, lines ~2733-2754) vs the current markdown
  schema (`artifact-schemas.md § Work STATE.md`), which explicitly permits work-owner-authored Q&A
  at the work level in FULL layout (channel "(b)").
- **Description:** work-009's SPEC decided `## Cross-phase Q&A` keeps a YAML key ONLY on the
  flattened Lite path (where it is AUTHORED); on the FULL path it is treated as pure DERIVED and
  must be empty. But the live markdown schema supports work-owner-authored Q&A at the work level in
  BOTH layouts. `work-005-knowledge-graph` is a live FULL-layout work carrying **29 substantial
  work-owner-authored Q&A entries** (Q1-Q28, ~1,000 lines of design-decision log) in its work-level
  `## Cross-phase Q&A`. The converter's DERIVED-narrative guard refuses that file
  ("conversion refused for this file (nothing dropped)"), so the work cannot be converted without
  either (a) giving full-layout work-level Q&A a YAML home, or (b) relocating/removing the entries.
  Its 36 child files (delivery + 35 tasks) DO convert -- so an unguarded run would leave the work in
  two formats (broken). The `migrate-work-hierarchy` remedy the WARN suggests does not apply: the
  work already has a hierarchy; the Q&A is legitimately authored, not un-migrated data.
- **Decision taken (task-010):** **work-005 deferred** by owner decision -- left fully as markdown
  (untouched, not half-converted), reads back-compat with graceful degradation. Only work-009
  (this work, flat layout) was converted. work-005's cutover is deferred until this gap is resolved.
- **Remedy (for the follow-up optimization work, which is redesigning where Q&A/audit lives):**
  give full-layout work-level Q&A an authored YAML home (keep the `qa:` key on the full path as a
  work-owner-authored channel), OR formally drop the work-level authored-Q&A channel in the schema
  and provide a relocation step. This is a SPEC + converter + both-reader-twins change, out of
  scope for work-009's plain translation.
- **See also:** [[KI-006]] (parent class -- writes with no YAML schema home); not catalogued in
  `tech-debt.md`

## KI-012: on current master, the Python and Node reader twins diverge on `delivery_state` for flat/hierarchical work payloads

- **Type:** Pre-existing product divergence (independent of this refactor); surfaced during crash-recovery re-authoring of the task-011 golden baseline.
- **Source:** `dashboard/reader/` (Python) includes a `delivery_state` value on each deliverable in the extracted work payload; `dashboard/server/reader.mjs` (Node) omits it (undefined) for the flat and hierarchical golden fixture shapes (`work-101-flat-golden`, `work-102-hier-golden`). `ki004_golden` agrees. (Also seen: `done_pct` renders `50.0` in Python vs `50` in Node -- harmless, equal by value.)
- **How it surfaced:** the crash lost the golden baseline JSON under `dashboard/reader/tests/fixtures/task011_golden/` (Bash-generated, not in the tool-recovery). Re-running the recovered `capture_golden.py` requires the PRE-refactor readers; the exact authoring commit (`21bf9636`) died with the unpushed crashed branch, so `origin/master` was used as the pre-refactor proxy. Against master, `old_python == old_node` holds for `ki004_golden` but NOT for `flat`/`hierarchical` -- so the golden's `test_legacy_read_no_parse_warning_recorded` meta-assertion (`old_python_equals_old_node`) fails. All 39 OTHER task-011 golden assertions pass; the recovered readers themselves are correct.
- **Scope ruling:** OUT of work-009's plain translation. This is a master-level twin divergence in `delivery_state` population, not something this refactor introduced or is chartered to fix. Routed here as a standalone finding (owner: "do 1 then 2"); to be investigated separately and, if real, promoted to `tech-debt.md`.
- **See also:** [[KI-004]] (a different, already-catalogued Python/Node `updated`-fallback divergence).
