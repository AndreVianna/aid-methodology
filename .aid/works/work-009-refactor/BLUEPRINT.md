# Delivery BLUEPRINT -- delivery-001: Convert Work-Tree STATE Files to YAML and Exclude Them From Review

> **Delivery:** delivery-001
> **Work:** work-009-refactor
> **Created:** 2026-08-12

---

## Objective

Make the work tracker under `.aid/works/` a data file instead of a document. Each in-scope
`STATE.md` -- the work-level file, and on the full path each `deliveries/delivery-NNN/STATE.md`
and `deliveries/delivery-NNN/tasks/task-NNN/STATE.md` -- becomes a `STATE.yml` carrying the same
keys, the same closed-enum strings and the same semantics, expressed as YAML instead of a YAML
frontmatter block wrapped in markdown prose. Nothing about *what* is tracked changes: same keys,
same enums, same single-writer rule, same read-time derivation; only the bytes move. Two
consequences make the delivery worth scoping as one unit. The machine writer stops maintaining
four hand-rolled markdown grammars (one write path replaces four awk programs -- the frontmatter
rewriter, the positional table writer, and two separate section replacers) and both
dashboard reader twins collapse their per-section line handlers onto one structured read. And
because the file stops looking like prose, it stops being handed to reviewers as prose: state
files are named out of the reviewable-artifact surface at the single upstream point every
reviewer brief derives from, so state churn in a reviewed diff is no longer gradeable content --
while the reviewer still *writes* its outcome into state, which was never the problem. Works
already on disk are converted by the CLI's existing per-repo format migration, so no in-flight
work is stranded and an adopter running an older CLI against a converted repo gets a named
diagnostic rather than an empty dashboard.

## Scope

Everything below is `Must` (`REQUIREMENTS.md §10`; `SPEC.md § Priority`). The **eleven** components
are `SPEC.md § Layers & Components` L-1 .. L-11; `SPEC.md § L-12` is *not* a component -- it is the
carry-forward register for open items. The requirement ids are `REQUIREMENTS.md §5`.

The bullets below **group** those components; they are not a one-to-one map onto them. Every one of
L-1 .. L-11 is named by at least one bullet, but two bullets cut across rather than adding a
component: *Render fan-out* is the FR-12 cross-cutting property of the components L-1 and L-2
already carry their own bullets for, and *Knowledge Base* is the FR-11 slice of the L-7 prose
surface. Counting bullets therefore over-counts components; the authoritative count is the eleven
in `SPEC.md`, and no bullet below introduces a twelfth.

- **The YAML serialization itself** (FR-1, FR-2a-c) -- filename `STATE.yml`, single document with
  no `---` fence, the three zones mapped (FRONTMATTER lifted verbatim to top-level keys; AUTHORED
  markdown tables/bullets become YAML structures; DERIVED sections absent from disk entirely), the
  declared five-shape YAML subset with its explicit reject list, and the three quoting modes with
  the implicit-typing deny list (`SPEC.md § Data Model` D-1 .. D-6).
- **Templates** (FR-3, L-1) -- `canonical/aid/templates/work-state-template.md`,
  `delivery-state-template.md`, `task-state-template.md` become `.yml` templates carrying the
  current zone documentation, enum hints, ordering block and single-writer notes as full-line YAML
  comments. Done first; everything binds to them.
- **The writer** (FR-4, FR-4a-c, L-2) -- `canonical/aid/scripts/execute/writeback-state.sh`: four
  awk programs collapse onto one single-key write path; the CLI surface, the `AID_*` override
  envs, the exit codes 0-6, every closed-enum validation, the sentinel lock and the
  write-to-temp + verify + atomic `mv` sequence are preserved; the `|` and newline guards are
  deleted (FR-4b).
- **The deliberate fork** (FR-4d) -- `dashboard/scripts/writeback-state.sh` is hand-updated, never
  resynced, and keeps accepting `Deploy` as a `Phase` value.
- **Both reader twins** (FR-5, FR-6, L-3, L-4) -- `dashboard/reader/{reader,parsers,state_schema}.py`
  and `dashboard/server/reader.mjs`: the existing hand-rolled `parse_frontmatter_scalars` /
  `parseFrontmatterScalars` pair is extended into the single state parser (no YAML library, no
  vendored parser), the per-section state machines and DERIVED/legacy line parsers are deleted,
  and graceful degradation plus the one-read-per-work cost property are preserved.
- **The shell readers** (FR-7, L-5) -- `canonical/aid/scripts/works/enumerate-works.sh` and
  `canonical/aid/scripts/housekeep/cleanup-classify.sh` retarget the filename and keep their
  degrade-to-sentinel behavior with no YAML dependency. These are two of the **three** shell state
  readers; the third, `dashboard/scripts/delete-pipeline.sh`, has its own bullet below because its
  read gates a destructive operation. No new shared `read-state.sh` accessor is introduced, and
  `SPEC.md § L-5` re-argues that on grounds that survive the third reader: a scalar accessor would
  serve only the `enumerate-works.sh` / `delete-pipeline.sh` pair (`cleanup-classify.sh` probes
  markdown structure, not frontmatter scalars), that pair is already one implementation by
  documented verbatim mirror, and the third reader is the one that cannot take a
  `dashboard/` -> `canonical/` runtime dependency without giving a destructive-operation guard a
  new way to fail open. The extraction trigger is restated as a *capability* (the first consumer
  needing a nested key, a sequence entry or the reject-list warnings), not a consumer count.
- **The delete-pipeline safety guard** (FR-7a, L-10) -- `dashboard/scripts/delete-pipeline.sh` is a
  **third** shell state reader, and the only one whose read gates a destructive operation: it reads
  `lifecycle` (`:348`) and refuses to delete a running pipeline (`:349`, exit 7). Both halves move
  together -- the path *and* its `_frontmatter_value` awk (`:164-168`), which loses its
  `NR==1 && $0=="---"` fence guard exactly as `enumerate-works.sh` does, because it is a documented
  verbatim mirror of that helper. Missing either half leaves an empty `LIFECYCLE` for every work,
  turning a safety guard into a silent no-op that permits deleting a running pipeline's work folder
  or worktree. Only one copy exists (no canonical source, no render, no PowerShell twin), so it is
  hand-edited. Gate: SP-19a; oracle `tests/canonical/test-delete-pipeline.sh`.
- **The dashboard server layer** (FR-4e, L-11) -- `dashboard/server/server.mjs` (`:1242`, `:1280`,
  `:1555`) and `dashboard/server/server.py` (`:1503`, `:1540`, `:1803`) each build `AID_STATE_FILE`
  as *work-dir* + `STATE.md` before spawning `writeback-state.sh` for the three write-enabled edit
  surfaces (task set-notes, pipeline `Lifecycle=Completed`, task rename); all six retarget to
  `STATE.yml`, in lockstep across the two runtimes (C-4). Because `AID_STATE_FILE` is an explicit
  override it wins over the writer's layout auto-detection, so an unretargeted site makes the
  writer die exit 1 on a nonexistent path and breaks every dashboard edit surface at once. Plus
  `dashboard/home.html:5816` (the raw-state viewer's fallback source label) and its ten sibling
  `STATE.md` UI strings. Gate: SP-19b; oracle
  `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py`.
- **Migration of on-disk works** (FR-9, L-6) -- a versioned hard cutover through the existing
  per-repo format engine: bump the format stamp to 4 in all four lockstep carriers (`bin/aid`,
  `bin/aid.ps1`, `lib/AidInstallCore.psm1`, `lib/aid-install-core.sh`) and append an idempotent
  conversion step to `_aid_migrate_repo` and its PowerShell twin.
- **The review exclusion** (FR-10a-d, L-8) -- three edits and one test:
  `canonical/aid/templates/reviewer-dispatch.md § ARTIFACTS UNDER REVIEW` gains the rule and the
  filter; `canonical/skills/aid-execute/references/reviewer-brief.md` stops naming a state row as
  reviewed content; `shortcut-engine.md § GATE` states the exclusion in each pass's `OUT OF SCOPE`
  bullet; and a test in the shape of `tests/canonical/test-kb-review-surface.sh` RS03 asserts it.
- **Skills, templates and prose** (FR-8, L-7) -- every recipe that names the path, copies a
  template or describes a retired section, plus the agent-context files (`CLAUDE.md`, `AGENTS.md`).
- **Knowledge Base** (FR-11, the KB slice of L-7) -- `artifact-schemas.md`,
  `pipeline-contracts.md`, `quality-gates.md`, `architecture.md`, `module-map.md`,
  `test-landscape.md`.
- **Render fan-out** (FR-12 -- a cross-cutting property of the already-counted L-1 and L-2, not a
  component of its own) -- canonical-only edits, then the profile generator and the dogfood
  `.claude/` / `.cursor/` resync.
- **Tests** (FR-13, L-9) -- the enumerated in-scope change-set, the added cross-format
  characterization/parity suite, the shared conformance corpus, and a re-bootstrapped
  `tests/coverage-baseline.tsv`.

**Out of scope:**

- **`.aid/knowledge/STATE.md`** -- the discovery-area / KB + cross-phase-process ledger stays
  markdown and stays a KB document (`kb-category: meta`, indexed by `build-kb-index.sh`), and is
  *already* review-exempt via `list_reviewable`. Its writer
  (`canonical/aid/scripts/summarize/writeback-state.sh`) and its readers (`graph-preflight.sh`,
  `discover-preflight.sh`, `kb-write-fence.sh`, `kb-freshness-check.sh`, `stale-check.sh`,
  `complexity-score.sh`) are untouched. In `reader.mjs` the two sites `join(kbDir, "STATE.md")`
  and `SKIP_NAMES` must NOT change -- a blind find-and-replace hits both, and editing either is a
  scope defect.
- **JSON as the target format** -- decided against in favour of YAML (`REQUIREMENTS.md §1`).
- **A JSON Schema artifact and any CI schema-validation gate** -- offered and declined (A-5).
  `writeback-state.sh`'s enum validation plus the conformance corpus remain the only machine
  checks.
- **`.aid/.temp/HOUSEKEEP_STATE_*.md`** -- the `aid-housekeep` run-state file; `housekeep-state.sh`
  is path-agnostic.
- **Control-signal and heartbeat files** (`.aid/.stop`, `.aid/.heartbeat/`) -- already outside the
  state file's single-writer scope by construction.
- **The authored documents** -- `tasks/task-NNN/DETAIL.md`, `REQUIREMENTS.md`, `SPEC.md`,
  `PLAN.md`, `BLUEPRINT.md` stay markdown and stay reviewable. The review exclusion applies to
  state files only.
- **Any change to the state model itself** -- no new field, no removed field, no widened or
  narrowed enum, no new zone, no change to the single-writer/disjoint-write rule, no change to
  most-advanced-wins reconcile ordering.
- **Retiring the DERIVED read-time union model** in favour of persisted rollups -- DERIVED
  sections stop being *represented on disk* (FR-2c), but the derivation itself is unchanged, and
  no rollup is ever persisted into a parent file (C-8).
- **`discovery-state-template.md`** -- untouched (it serves the out-of-scope ledger).
- **`canonical/aid/scripts/migrate/migrate-work-hierarchy.{sh,ps1}`** -- triaged OUT of the
  change-set by `SPEC.md § L-6`. It is an *era* migration: markdown-in, markdown-out, its output
  feeding the format-4 converter as the next step. Consequently
  `tests/canonical/test-migrate-hierarchy.sh` (89 `STATE.md` references) and the fixture tree
  `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/` are also out of the FR-13
  change-set and must stay untouched. This is a deliberate scope *reduction* against
  REQUIREMENTS FR-13's candidate inventory, not an omission.
- **A standalone hand-run converter script, and any dual-read compatibility window** -- both
  rejected in `SPEC.md § L-6`; the conversion rides the existing CLI format-stamp engine.
- **The five discovery-ledger-only test suites** -- `test-discover-preflight.sh`,
  `test-summarize-preflight.sh`, `test-kb-freshness-check.sh`, `test-grade-summary.sh`,
  `test-kb-review-surface.sh` reference only the out-of-scope ledger; editing one is itself a scope
  defect.
- **`grade.sh`** -- unmodified (FR-10d). No new ledger column, severity, grade mechanism or gate.
- **Repairing the known staleness carried forward in `SPEC.md § L-12`** -- `cleanup-classify.sh`'s
  `> **Status:**` / `## Deploy Status` signals, the work-level `parse_quick_check_findings` /
  `parse_delivery_gate` detail-view parsers, and `delete-pipeline.sh`'s fail-open on a genuinely
  **missing** state file, all already return empty/`fail:`/no-guard against a current-shape work.
  Behavior is preserved as-is and each finding is routed onward; repairing any of them
  would be an observable behavior change this `restructure` forbids. What L-10 *does* fix is
  narrower and mandatory: the guard must keep firing for a `Running` work after the rename.
- **NFR-10, a performance budget** -- *(pending)* in REQUIREMENTS and left pending: no measured
  baseline for reader parse time exists and the refactor is not performance-motivated. Only the
  structural cost property is asserted (see the SP-10 gate criterion below).

## Gate Criteria

Each criterion below is the delivery-gate form of the correspondingly-numbered
`SPEC.md § Acceptance Criteria` entry (SP-1 .. SP-20), which in turn back-traces to
`REQUIREMENTS.md §9` AC-1 .. AC-13.

- [ ] **SP-1 -- subset conformance.** A shared conformance corpus of small `STATE.yml` inputs, each
      paired with its expected parse result -- one per permitted shape S1-S5, one per quoting mode,
      one per implicit-typing deny-list literal, and one per rejected construct (tab indentation,
      a flow collection other than the literal `[]`/`{}`, a block scalar, an anchor/alias/tag/
      directive, a second document, indentation not a multiple of two, nesting deeper than S5, and a
      line that is *neither* a `key:` line *nor* a `- `-prefixed sequence entry) -- is run
      identically by both reader twins. Both produce identical values and an identical warning set;
      every rejected construct emits the same `parse_warning`, skips exactly that key, keeps
      parsing, and raises no exception in either runtime. The corpus additionally covers the two
      malformations whose declared disposition is *not* skip-the-key, each asserted in its
      `SPEC.md § Data Model` D-3 form so the twins cannot diverge by host-language semantics: a
      duplicate key at the same level (**last wins** *and* warn) and a byte-order mark (**stripped**
      and warned). And it carries the **converse** case for the last of the rejects above: a bare
      `- value` scalar sequence entry (the S5 form `delivery_gate.issue_list` uses) must **parse**,
      not warn -- a literal "reject every line with no `key:` separator" reading would drop every
      gate issue entry and let the two twins diverge on which rule wins.
- [ ] **SP-2 -- key and enum identity.** A recorded comparison of the key set and the enum-value set
      on disk at all three levels, pre-refactor versus post-refactor, is empty of differences: no
      key added, renamed or removed; no enum string changed. The single documented exception is
      `display_name` -- already written by `writeback-state.sh` today but never declared in the task
      template -- and the comparison records it explicitly as a documentation fix, not a schema
      change.
- [ ] **SP-3 -- DERIVED stays derived, and is not lost.** A converted work carries no key for
      Features State, Plan/Deliveries, Tasks State, Delivery Gates, Calibration Log or Dispatches,
      and both readers derive the same union they derive today. Given a legacy file whose DERIVED
      section holds a real (non-placeholder) row, the conversion of **that file** is refused rather
      than dropping data: the converter helper returns non-zero naming the file and the section, no
      `STATE.yml` is written and the `STATE.md` stays in place. The enclosing `_aid_migrate_repo`
      step logs `WARN:` with the remedy and the CLI still exits 0, because the engine's documented
      contract is that every step is WARN-not-fail and the function always returns 0
      (`bin/aid:2012-2013`) -- so the guard is asserted at the helper's level, which is where a
      non-zero exit is meaningful. The refused file stays diagnosable via SP-9's legacy detector and
      is converted by a later `aid update` once its DERIVED row is resolved.
- [ ] **SP-4 -- surgical single-key write.** For a `STATE.yml` at any of the three levels, writing
      one key reproduces every **pre-existing** line other than that key's own line byte-for-byte --
      full-line comments, blank lines, key order and the presence/absence of a trailing newline all
      survive. Diff size follows from whether the key's parent exists: writing an **existing** key
      yields a `git diff` of exactly one line; writing a nested key whose parent mapping is absent
      yields exactly the writer's existing `create-parent-if-absent` insertion (the parent key line
      plus the indented child line, printed by the closing-fence flush rule
      `writeback-state.sh:597-615`, parent-absent branch `:606-610`) and nothing more -- *not* the
      `NR == 1` synthesize-a-whole-block branch (`:581-595`), which `SPEC.md § D-1` retires. The
      gate asserts
      the byte-invariance in both cases and the one-line diff only in the first -- asserting it
      unconditionally would fail the gate on the first write to a newly-added task, which is the
      normal path, not an edge case.
- [ ] **SP-5 -- writer CLI contract preserved, restriction lifted.** Every documented write mode
      (`--pipeline --field`, `--task-id --field`, `--task-id --findings`, `--delivery-id --block`,
      `--lifecycle`, `--gate-field`, `--append-issue`) keeps its CLI surface, its `AID_*_FILE`
      override envs and its exit-code contract (0/1/2/3/4/5/6); an out-of-enum value still fails
      with exit 4; and a value containing `|`, a newline, a colon, a `#` or a quote round-trips
      intact instead of being rejected. Asserted by the writer's own harness,
      `tests/canonical/test-writeback-state.sh` (Unit 14's `|` rejection inverts, and that
      inversion is an enumerated change-set entry).
- [ ] **SP-6 -- atomicity and byte fidelity.** With N parallel writers on one file, each write is
      either fully applied or reports exit 2, the file parses at every observable moment, and no
      write is silently lost -- the scenario `tests/canonical/test-disjoint-merge.sh` already
      models. A write that fails verification leaves the original byte-unchanged, and a CRLF source
      or a source with no trailing newline round-trips on both Windows and POSIX awk builds.
- [ ] **SP-7 -- layout detection unchanged.** For a flattened Lite work and a full work, the
      writer, both reader twins and the skill recipes all apply the identical three-part rule
      (work-root BLUEPRINT present AND `tasks/task-NNN/DETAIL.md` present AND no `deliveries/`),
      retargeted only from `STATE.md` to `STATE.yml` wherever the filename appears.
- [ ] **SP-8 -- cross-format, cross-runtime characterization (golden-master form).** Three parts,
      because the comparison is against a **recorded** legacy payload rather than a live one -- this
      SPEC deletes the markdown state parsers, so no post-refactor read of a legacy `STATE.md` can
      be field-equal to anything (it is diagnosed, not parsed: SP-9). (a) The legacy-markdown
      fixture read by the **pre-refactor** Python and Node readers yields two payloads equal on
      every rendered field with no `parse_warning`, and that payload is committed as the golden
      baseline. (b) The same tree after conversion, read by the **post-refactor** Python and Node
      readers, yields two payloads each equal to the golden baseline on every rendered field
      (lifecycle, phase, active skill, updated, delivery state, gate tier/grade/timestamp, per-task
      state/review/elapsed/notes/display-name, lifecycle-history rows, Q&A entries, derived counts
      and percentages), with no `parse_warning`. (c) The **unconverted** legacy tree read by the
      post-refactor readers returns the minimal-model degradation with the same `parse_warning`
      naming the file and the migration command in both runtimes -- the required outcome, not a
      shortfall of (b). Both layouts are covered. Home: the cross-runtime parity suite family
      (`dashboard/reader/tests/test_flattened_layout_parity.py` for flat,
      `test_task014_fixtures.py`'s hierarchical fixture for full).
- [ ] **SP-9 -- graceful degradation.** For a state file that is absent, empty, truncated
      mid-document, valid-but-carrying-an-unknown-key, or a leftover legacy `STATE.md`, each twin
      returns a best-effort model with a `parse_warning` naming the file, raises no exception, and
      the dashboard still lists the work. For the legacy case the warning names the migration
      command.
- [ ] **SP-10 -- read cost and bounded read.** The always-on read pass performs exactly one file
      read per work (reused by the detail path for `raw_state`, with no re-read), adds no stat and
      no glob, and the existing bounded-read protection (`dashboard/reader/io_bounds.py`,
      `MAX_READ_BYTES` in `reader.mjs`) applies to the new filename.
- [ ] **SP-11 -- shell readers.** `enumerate-works.sh` and `cleanup-classify.sh` report the same
      `phase`/`lifecycle` and the same classification signals as before against a converted work,
      degrade to the `--` sentinel rather than failing on a missing or unreadable file, name the new
      filename in their diagnostics, and take no YAML dependency.
- [ ] **SP-12 -- migration of on-disk works.** Against a repository with legacy-format works across
      one or more worktree roots covering both layouts, the format migration replaces every
      in-scope `STATE.md` with a `STATE.yml` preserving every scalar, every table row and every Q&A
      entry; the `.md` is gone; a second run changes nothing (for a fully converted work -- a file
      the SP-3 DERIVED guard refused is converted on a later run once its DERIVED row is resolved,
      and is *expected* to change then); the repo format stamp advances;
      `enumerate-works.sh` reports the same values as before; both twins render every work with no
      `parse_warning`; and the Bash and PowerShell twins produce identical results on identical
      input. Oracles: `tests/canonical/test-aid-migrate.sh`, `test-aid-migrate-trigger.sh`,
      `test-release-migrate-smoke.sh`, `test-aid-cli-parity.sh`.
- [ ] **SP-13 -- review exclusion, surface and grading.** For a per-delivery and a per-task review
      dispatch, no state file appears in the derived `{{ARTIFACTS}}` -- enforced by the exclusion
      rule and filter defined once in `reviewer-dispatch.md § ARTIFACTS UNDER REVIEW`, by no
      per-skill brief naming a state row as reviewed content, and by a new test in the shape of
      `tests/canonical/test-kb-review-surface.sh` RS03 that drops every state-file path shape (all
      three levels, both layouts, `.md` legacy and `.yml`) while keeping every authored-artifact
      path. For a completed cycle whose diff includes state churn, no ledger row cites a state file
      as its `Doc`, the grade equals the grade the same review produces without that churn, and
      `canonical/aid/scripts/grade.sh` is unmodified.
- [ ] **SP-14 -- render and fork integrity.** With the canonical edits complete, the profile
      generator run in full (`run_generator.py`, not a per-script renderer) and the dogfood trees
      resynced from `profiles/claude-code/`: `tests/canonical/test-dogfood-byte-identity.sh` and
      `tests/canonical/test-multitool-isolation.sh` (T21-T26) pass, the render-drift check is
      clean, all five profile renders carry the change, no render was hand-edited, and
      `dashboard/scripts/writeback-state.sh` still accepts `Deploy` as a `Phase` value -- the only
      available proof it was hand-updated rather than resynced.
- [ ] **SP-15 -- documentation *and consumer* truth.** A search for `STATE.md` and for the retired
      markdown section headings (`## Lifecycle History`, `### Tasks lifecycle`, `## Tasks State`,
      `## Delivery Gate`, `## Quick Check Findings`) across every KB doc, skill, template,
      agent-context file, profile render, dogfood tree **and every operational consumer under
      `dashboard/`** -- specifically `dashboard/scripts/` (the `delete-pipeline.sh` guard and the
      `writeback-state.sh` fork), `dashboard/server/` (`server.mjs`, `server.py`, `reader.mjs`) and
      `dashboard/home.html` -- leaves no surviving reference that describes an in-scope work-tree
      state file as markdown or as a reviewable artifact, and none that *resolves a path to one*;
      every remaining `STATE.md` occurrence is either the out-of-scope discovery-area ledger
      (`join(kbDir, ...)`, `SKIP_NAMES`) or an explicitly labelled legacy/migration reference. The
      `dashboard/` half is named explicitly because a docs-and-renders-only search does not reach
      L-10 or L-11 -- neither lives in a doc, a skill, a
      template or a render. No KB doc names this work or its folder path, and the KB mechanical gates
      (`kb-citation-lint.sh`, `lint-frontmatter.sh`, `build-kb-index.sh` freshness,
      `closure-check.sh` -- `quality-gates.md § Mechanical Gates Run by the Orchestrator`) pass.
- [ ] **SP-16 -- behavior preservation.** The pre-refactor per-test pass/fail set is recorded as a
      baseline from each suite's own summary line (never a grep over stdout) across
      `bash tests/run-all.sh` and `python -m pytest dashboard/reader/tests dashboard/server/tests`
      (`test-landscape.md § Test Commands`); the post-refactor set matches it exactly except for
      tests enumerated in the change-set as intended format-asserting updates. Any other
      newly-failing test, and any newly-*passing* test not on that list, is a regression.
      `tests/coverage-baseline.tsv` is re-bootstrapped, not row-edited, because the change is
      corpus-wide.
- [ ] **SP-17 -- dependency floor.** Both reader twins run in a clean environment with no
      third-party packages installed and parse state files successfully, and
      `packages/pypi/pyproject.toml` (`dependencies = []`) and the repo-root `package.json`
      dependency block are unchanged.
- [ ] **SP-18 -- self-hosting sequencing.** At each landed stage: the readers, the shell readers and
      the CLI accept `STATE.yml` *before* any live work tree is converted; this work's own state
      remains writable and readable at every step in whichever format is live at that moment; and no
      step leaves the repository with works in two formats at the end of that step.
- [ ] **SP-19 -- the two operational consumer layers keep working.** Both halves are asserted
      *behaviorally*, not by a text search, because both layers fail **silently** on a textual miss.
      **(a) The delete-pipeline guard (L-10).** Against a converted work whose `STATE.yml` carries
      `lifecycle: Running`, `dashboard/scripts/delete-pipeline.sh` still refuses and exits 7 --
      proving the rename left the guard firing rather than turning it into an unconditional no-op
      that permits deleting a running pipeline's work folder. Oracle:
      `tests/canonical/test-delete-pipeline.sh`. **(b) The dashboard server write path (L-11).**
      Against a converted work, each of the three write-enabled dashboard edit surfaces (task
      set-notes, pipeline `Lifecycle=Completed`, task rename) writes successfully to `STATE.yml` in
      **both** server runtimes with identical results, and the raw-state viewer resolves the same
      source path in both. Oracle:
      `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py`.
- [ ] **SP-20 -- template shape, the two mechanical rules.** Each of the three delivered `.yml`
      templates satisfies both rules `SPEC.md § L-1` makes normative: **(a)** no writer-owned key
      carries a trailing inline comment (every zone note, enum hint and single-writer annotation is
      a full-line comment *above* its key), and **(b)** no key whose real value must be readable
      before the first write carries an un-instantiated `{...}` placeholder. Both are grep-level
      checks. Rule (a) exists because `WB_SET_FRONTMATTER_AWK` replaces the **entire** line for the
      key it writes (`writeback-state.sh:619`), so a trailing comment on a writer-owned key is
      destroyed on the first write to it -- silently, and only for the keys written so far. Rule (b)
      exists because the readers' placeholder skip (`state_schema.py:82`) is a safety net against a
      leaked placeholder, not a licence to ship one. This is the gate that gives FR-3 and FR-2b an
      explicit criterion of their own, and it guards a **live** recurrence: today's
      `work-state-template.md` breaks (a) on `pause_reason`, `block_reason`, `block_artifact`,
      `ticket_ref` and `pipeline.path`/`pipeline.initiator`. Oracle:
      `tests/canonical/test-work-state-template.sh`, retargeted to the `.yml` templates.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | RESEARCH | Record the pre-refactor test baseline and triage the FR-13 test change-set |
| task-002 | REFACTOR | Convert the three work-tree state templates to the YAML subset |
| task-003 | REFACTOR | Rebuild the Python reader twin onto one structured state parse |
| task-004 | REFACTOR | Port the Node reader twin onto the same structured state parse |
| task-005 | TEST | Shared cross-runtime YAML-subset conformance corpus |
| task-006 | REFACTOR | Retarget the three shell state readers to STATE.yml |
| task-007 | REFACTOR | Collapse writeback-state.sh onto one YAML single-key write path |
| task-008 | MIGRATE | Add the format-4 state conversion step to the repo migration engine |
| task-009 | CONFIGURE | Bump AID_SUPPORTED_FORMAT to 4 across the four lockstep carriers |
| task-010 | MIGRATE | Convert every live work tree in this repository to STATE.yml |
| task-011 | TEST | Cross-format, cross-runtime characterization suite |
| task-012 | IMPLEMENT | Exclude state files from the reviewable-artifact surface |
| task-013 | TEST | Test the state-file review exclusion, in the RS03 shape |
| task-014 | DOCUMENT | Retarget every skill recipe, template and agent-context reference |
| task-015 | TEST | Update the in-scope canonical shell suites to the YAML state format |
| task-016 | TEST | Update the in-scope dashboard reader/server suites to the YAML state format |
| task-017 | CONFIGURE | Render fan-out -- regenerate the five profiles and resync the dogfood trees |
| task-018 | DOCUMENT | Update the Knowledge Base to the YAML state format |
| task-019 | TEST | Post-refactor behavior-preservation verification and coverage re-bootstrap |
| task-020 | REFACTOR | Retarget the dashboard server write path and raw-state labels to STATE.yml |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-refactor (refactor, artifact '').

Sequencing constraints a later executor must not lose (`SPEC.md § L-6 Live works during the
conversion`, C-6, SP-18):

- **Reader and CLI support land before any conversion.** The templates and the declared subset come
  first (L-1), then both reader twins (L-3, L-4), the shell readers (L-5), the writer (L-2), the
  dashboard server layer (L-11) and the
  format gate -- and only then is any work tree converted. Shipping a converted work ahead of reader
  support is the "reader support shipped, adopters stranded" failure C-6 exists to prevent, and a
  repo-local fix does not reach an already-installed `aid` until it is reinstalled -- the conversion
  runs through the *installed* CLI (`aid update`), not through `bin/aid` in this tree, so that
  reinstall is an explicit step of `task-010` (or a final step of `task-009`) rather than a task
  edge.
- **No two-format end state.** Both twins enumerate *every* work across *every* worktree root, so a
  half-converted repo renders a half-broken dashboard. The conversion of the repo's own works is a
  single step, and no step may end with works in both formats.
- **Live works exist right now, across several roots -- and the set is enumerated at execution
  time, never from a list in a document.** `task-010`'s FIRST step is to enumerate the live works
  itself, across every worktree root, via
  `.claude/aid/scripts/works/enumerate-works.sh` (or the equivalent
  `git worktree list` + `ls <root>/.aid/works/` sweep) and to record that enumeration as the
  authority for the run. No document here is that authority: the set demonstrably moves *during* a
  single run -- two additional worktrees appeared between this delivery being authored and its GATE
  pass. As an **illustrative snapshot only** (accurate when written, guaranteed stale later), on
  2026-08-12 the roots were the master checkout plus the `work-003`, `work-004`, `work-006`,
  `work-007`, `work-008`, `work-009` and `work-010` worktrees, carrying live works `work-003`,
  `work-004`, `work-005`, `work-006`, `work-007`, `work-008`, `work-009` and `work-010`. One work,
  `work-005-knowledge-graph`, is *tracked on master* and therefore materializes under **every**
  root, while the rest are untracked per-worktree state -- so converting it once produces a change
  every other root inherits, and the converter must be idempotent against roots that already see
  the converted form. That tracked/untracked distinction is a structural property worth stating;
  the roster is not. A tree still holding markdown state after the cutover is diagnosed by the
  format gate and the reader warning, and repaired by `aid update`.
- **This work's own state file is itself in scope.** `work-009-refactor`'s tracker is one of the
  files being converted, and the tracking-discipline mandate keeps binding throughout: every state
  write during this work happens in whichever format is live at that moment, and the conversion step
  must leave this work's own tracking readable and writable immediately afterwards.
- **Ordering inside the migration path.** Hierarchy migration first, format conversion second --
  `migrate-work-hierarchy.{sh,ps1}` is markdown-in/markdown-out and feeds the format-4 converter as
  the next step. Document that order in the script header and in the KB.
- **The wave table is the topological minimum.** Every wave in `PLAN.md § Execution Graph` is
  `1 + max(wave of dependencies)` over all twenty tasks. An ordering that holds only by that
  arithmetic MUST still be encoded as a dependency edge, and encoding it can leave the wave table
  unchanged -- which is exactly why a missing edge is easy to miss.
- **Final-state summaries refresh once, at the end.** `.aid/knowledge/INDEX.md` and `kb.html` are
  regenerated once when the work is complete, not per step (`REQUIREMENTS.md §10` item 7).
