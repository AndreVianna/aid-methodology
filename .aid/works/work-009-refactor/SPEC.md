# Convert Work-Tree STATE Files to YAML and Exclude Them From Review

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-12 | SPEC authored from REQUIREMENTS.md | /aid-refactor |
| 2026-08-12 | GATE Pass 1 -- definition documents corrected across the pass's REVIEW/FIX cycles | /aid-refactor GATE |

## Source

Every claim in the requirements-half below is a synthesis of, and traceable to, these
REQUIREMENTS.md sections:

- `REQUIREMENTS.md §1 Objective` -- the stakeholder's two-part ask, the captured family slots
  (Target / Refactor kind = `restructure` / Rationale / Behavior-preservation guarantee), and the
  YAML-over-JSON decision.
- `REQUIREMENTS.md §2 Problem Statement` -- the three-zone table and the four evidenced pains.
- `REQUIREMENTS.md §3 Users & Stakeholders` -- the seven consumer roles whose needs the
  `## User Stories` below restate.
- `REQUIREMENTS.md §4 Scope` (In Scope / Out of Scope) -- the boundary this SPEC designs against;
  nothing below widens it.
- `REQUIREMENTS.md §5 Functional Requirements` -- FR-1 .. FR-13 (incl. FR-4a-e and FR-7a), the
  substance `## Technical Specification` settles.
- `REQUIREMENTS.md §6 Non-Functional Requirements` -- NFR-1 .. NFR-10.
- `REQUIREMENTS.md §7 Constraints` -- C-1 .. C-9.
- `REQUIREMENTS.md §8 Assumptions & Dependencies` -- A-1 .. A-6 (each settled or carried in
  `### Data Model` / `### Layers & Components` below) and the dependency inventory.
- `REQUIREMENTS.md §9 Acceptance Criteria` -- AC-1 .. AC-13; every SPEC acceptance criterion
  below carries an explicit back-trace to one or more of them.
- `REQUIREMENTS.md §10 Priority` -- `Must` for the whole of FR-1 .. FR-13, plus the seven-step
  dependency ordering this SPEC's sequencing rule (`### Layers & Components §L-6`) refines.

Knowledge Base grounding: `artifact-schemas.md` (State-File Hierarchy, Work/Delivery/Task
STATE.md, Validation), `pipeline-contracts.md` (on-disk work hierarchy, per-skill state
machines), `architecture.md` (canonical -> profiles render, "editing a render is a defect",
Polyglot parity), `module-map.md` (dashboard reader/server modules), `coding-standards.md`
(exit codes, stdout/stderr split, configuration-access rule), `test-landscape.md` (suite
inventory, run-all entrypoint, coverage-parity gate), `quality-gates.md` (reviewer ledger,
grade.sh, GATE), `technology-stack.md` (runtimes and version floors).

## Description

The work tracker under `.aid/works/` stops being a document and becomes a data file. Each
`STATE.md` in a work tree -- the work-level file, and on the full path each
`deliveries/delivery-NNN/STATE.md` and `deliveries/delivery-NNN/tasks/task-NNN/STATE.md` --
becomes a `STATE.yml` holding the same fields, the same closed-enum values and the same
semantics, expressed as YAML instead of a YAML frontmatter block wrapped in markdown prose.
Nothing about *what* is tracked changes: same keys, same enums, same single-writer rule, same
read-time derivation. Only the bytes move.

Two things follow from that. First, the machine writer and the two machine readers stop
maintaining hand-rolled markdown-table and markdown-section grammars: one write path replaces
four awk programs, and the per-section line handlers in both reader twins collapse onto one
structured read. Second, the file stops looking like prose, so it stops being handed to
reviewers as prose: state files are named out of the reviewable artifact surface at the single
upstream point every reviewer brief derives from, and state churn in a reviewed diff is no
longer gradeable content. The reviewer still *writes* its outcome into state -- writing state
was never the problem.

Works already on disk are converted by the CLI's existing per-repo format migration, so no
in-flight work is stranded, and an adopter who runs an older CLI against a converted repo gets
a named diagnostic rather than an empty dashboard.

## User Stories

- As a **pipeline agent**, I want to write one state field without any value-shape restriction
  (no "no pipes, no newlines" rule) so that I can record a real note or block reason verbatim
  at the instant a transition happens.
- As the **state writer** (`writeback-state.sh`), I want one parse-and-serialize path instead of
  a frontmatter rewriter, a positional markdown-table cell writer and *two* section replacers
  (one for `## Quick Check Findings`, one for `## Delivery Gate`), so that a new field is one code
  change rather than four.
- As a **dashboard reader twin**, I want to read a structure rather than agree with my other-
  language twin on a markdown grammar, so that parity is a property of one small parser instead
  of a dozen per-section line handlers.
- As a **shell consumer** (`enumerate-works.sh`, `cleanup-classify.sh`,
  `dashboard/scripts/delete-pipeline.sh`), I want a cheap scalar
  lookup that still needs no YAML dependency, so that listing, cleanup and the delete guard keep
  working in a bare shell.
- As a **reviewer**, I want state files never to appear in my artifact list, so that I grade
  authored artifacts and never grade a machine ledger against a prose rubric.
- As an **AID maintainer**, I want one canonical edit point that renders to five profiles plus
  the two dogfood trees (seven renders in all), with the one deliberate fork left alone, so that
  the byte-identity gate stays green and no adopter receives a half-converted toolkit.
- As an **adopter with an in-flight work**, I want my existing state converted in place by a
  command I already run, so that upgrading does not cost me my tracking.

## Priority

**Must** -- the whole of `REQUIREMENTS.md §5` FR-1 .. FR-13. The ask has exactly two halves
(format conversion, review exclusion) and neither is optional; every other functional
requirement is a consumer that breaks if skipped. Nothing is Should or Could.

Explicitly deferred (unchanged from `REQUIREMENTS.md §10`): a JSON Schema artifact and a CI
schema-validation gate (A-5). `NFR-10` (performance budget) stays *(pending)* -- see
`### Layers & Components §L-12`.

## Acceptance Criteria

Each criterion names the REQUIREMENTS.md requirement it discharges. Reverse traceability:
REQUIREMENTS AC-1 -> SP-16; AC-2 (a/b/c) -> SP-8; AC-3 -> SP-4, SP-5; AC-4 -> SP-6;
AC-5 -> SP-9; AC-6 -> SP-13; AC-7 -> SP-13; AC-8 -> SP-12; AC-9 -> SP-2, SP-3, SP-20; AC-10 -> SP-14;
AC-11 -> SP-15; AC-12 -> SP-17; AC-13 (a/b) -> SP-19. Every REQUIREMENTS acceptance criterion is
covered **whole** -- no criterion is discharged by a SPEC criterion that asserts less than it
does -- and every criterion below traces back to at least one requirement.

Forward traceability is checked the same way, and it is what added SP-20: **FR-2b** (AUTHORED
markdown body -> YAML structures) and **FR-3** (the templates themselves) appeared in no criterion's
`traces:` line, so the template conversion -- the artifact everything else binds to -- had no gate
of its own. SP-20 closes that; FR-2b is additionally asserted through SP-2/SP-3's key identity and
SP-16's change-set, and FR-3 through SP-20 and SP-14's render integrity.

- [ ] **SP-1 (subset conformance).** Given the declared YAML subset (`### Data Model §D-3`),
      when a state file uses only shapes S1-S5 with the declared quoting rules, then both reader
      twins parse it identically; and when a file uses any rejected construct (tab indentation,
      flow collection other than the empty `[]`/`{}`, block scalar, anchor/alias/tag/directive,
      second document, odd indentation, over-deep nesting), then both twins emit the same
      `parse_warning`, skip exactly that key, and raise no exception.
      *(traces: FR-6, NFR-1, NFR-2, AC-12)*
- [ ] **SP-2 (key and enum identity).** Given a migrated work at each of the three levels, when
      the set of keys and the set of enum values on disk is compared to the pre-refactor set,
      then they are identical -- no key added, renamed or removed, no enum string changed. The
      one documented exception is `display_name`, which the writer already writes today
      (`writeback-state.sh:829`) but the task template never declared; declaring it is a
      documentation fix, recorded as such in the comparison, not a schema change.
      *(traces: FR-1, FR-2a, AC-9, C-5, A-2)*
- [ ] **SP-3 (DERIVED stays derived, and is not lost).** Given a converted work, when its
      state file is inspected, then no key exists for Features State, Plan/Deliveries, Tasks
      State, Delivery Gates, Calibration Log or Dispatches, and both readers derive the same
      union they derive today. Given a legacy file whose DERIVED section holds a real
      (non-placeholder) row, when the converter runs, then **the conversion of that file is
      refused**: the converter helper returns non-zero naming the file and the section, writes no
      `STATE.yml`, and leaves the `STATE.md` in place, so nothing is dropped. The enclosing
      `_aid_migrate_repo` step surfaces that as a `WARN` and the CLI still exits 0, per the
      engine's own always-return-0 contract (`bin/aid:2012-2013`) -- see `§L-6` step 2 for why
      that is the correct disposition and why the refused file stays diagnosable.
      *(traces: FR-2c, AC-9, A-4, C-8)*
- [ ] **SP-4 (surgical single-key write).** Given a `STATE.yml` at any level, when one key is
      written, then every **pre-existing** line other than that key's own line is reproduced
      byte-for-byte -- full-line comments, blank lines, key order and the presence/absence of a
      trailing newline all survive. The diff size follows from whether the key's parent exists:
      writing an existing key yields a **one-line** `git diff`; writing a nested key whose parent
      mapping is absent yields exactly the minimum insertion the writer already performs
      (`create-parent-if-absent`: the parent key line plus the indented child line, emitted by
      the closing-fence flush rule `writeback-state.sh:597-615` -- specifically its
      parent-absent branch `:606-610`, where `!parent_seen` prints a fresh parent header and
      then the indented child) and nothing more. The absolute is the byte-invariance of
      pre-existing lines; the one-line diff is its consequence in the common case, not a separate
      claim -- stating it unconditionally would make the criterion fail on the first write to a
      newly-added task.
      *(traces: FR-4a, NFR-5, AC-3)*
- [ ] **SP-5 (writer CLI contract preserved, restriction lifted).** Given each documented write
      mode (`--pipeline --field`, `--task-id --field`, `--task-id --findings`,
      `--delivery-id --block`, `--lifecycle`, `--gate-field`, `--append-issue`), when it is
      invoked, then the CLI surface, the `AID_*_FILE` override envs and the exit-code contract
      (0/1/2/3/4/5/6) are unchanged, an out-of-enum value still fails with exit 4, and a value
      containing `|`, a newline, a colon, a `#` or a quote round-trips intact instead of being
      rejected.
      *(traces: FR-4, FR-4b, AC-3)*
- [ ] **SP-6 (atomicity and byte fidelity).** Given N parallel writers on one file, when they
      all complete, then each write is either fully applied or reports exit 2, the file parses
      at every observable moment, and no write is silently lost; given a write that fails
      verification, the original is byte-unchanged; given a CRLF source or a source with no
      trailing newline, both properties round-trip on Windows and POSIX awk builds.
      *(traces: NFR-3, NFR-4, FR-4c, AC-4)*
- [ ] **SP-7 (layout detection unchanged).** Given a flattened Lite work and a full work, when
      the writer, both reader twins and the skill recipes detect the layout, then all of them
      apply the identical three-part rule (work-root BLUEPRINT present AND
      `tasks/task-NNN/DETAIL.md` present AND no `deliveries/`), retargeted only from `STATE.md`
      to `STATE.yml` where the filename appears.
      *(traces: FR-4, FR-5)*
- [ ] **SP-8 (cross-format, cross-runtime characterization -- golden-master form).** The
      comparison is against a **recorded** legacy payload, not a live one. Field equality across
      all four legacy/converted x Python/Node payloads MUST NOT be demanded:
      it is unsatisfiable by construction, because this
      SPEC deletes the markdown state parsers (`§L-3`, `§L-4`) and specifies that a legacy
      `STATE.md` is *diagnosed, not parsed* (`§L-6`, SP-9) -- a `_minimal_work_model` cannot carry
      per-task state, lifecycle-history rows, Q&A entries or derived counts, so no post-refactor
      read of a legacy file can be field-equal to anything. Keeping those parsers alive to satisfy
      it would forfeit the work's entire rationale. Three parts:
      - **(a) Record the baseline.** Given the legacy-markdown fixture tree read by the
        **pre-refactor** Python and Node readers, then the two payloads are equal on every
        rendered field and neither raises a `parse_warning`; that payload is committed as the
        golden baseline (it is a fixture, not a work-folder artifact --
        `CLAUDE.md § Tracking discipline`).
      - **(b) Compare the conversion.** Given the same tree after the `§L-6` conversion, read by
        the **post-refactor** Python and Node readers, then both payloads equal the golden
        baseline on every rendered field (lifecycle, phase, active skill, updated, delivery state,
        gate tier/grade/timestamp, per-task state/review/elapsed/notes/display-name,
        lifecycle-history rows, Q&A entries, derived counts and percentages), and neither raises a
        `parse_warning`.
      - **(c) Prove the legacy read degrades identically.** Given the *unconverted* legacy tree
        read by the post-refactor readers, then both return the minimal-model degradation with the
        same `parse_warning` naming the file and the migration command. This is the required
        behavior (SP-9, AC-5), not a shortfall of (b).
      Both layouts are covered. Together (a)+(b)+(c) discharge REQUIREMENTS AC-2 in full,
      including its "no `parse_warning`" clause -- which AC-2 now scopes to the two reads where it
      is achievable (the pre-refactor legacy read and the post-refactor converted read) instead of
      to "either format", because the post-refactor legacy read is *required* to warn.
      *(traces: AC-2 a/b/c, NFR-1, C-4)*
- [ ] **SP-9 (graceful degradation).** Given a state file that is absent, empty, truncated
      mid-document, valid-but-carrying-an-unknown-key, or a leftover legacy `STATE.md`, when
      either twin reads the work, then it returns a best-effort model with a `parse_warning`
      naming the file, raises no exception, and the dashboard still lists the work; for the
      legacy case the warning names the migration command.
      *(traces: FR-5, NFR-8, AC-5)*
- [ ] **SP-10 (read cost and bounded read).** Given the always-on read pass, when a work is
      read, then exactly one file read occurs per work (reused by the detail path for
      `raw_state`, with no re-read), no stat or glob is added, and the existing bounded-read
      protection applies to the new filename.
      *(traces: FR-5, NFR-6, NFR-9)*
- [ ] **SP-11 (shell readers).** Given `enumerate-works.sh` and `cleanup-classify.sh`, when they
      read a converted work, then they report the same `phase`/`lifecycle` and the same
      classification signals as before, they degrade to the `--` sentinel rather than failing on
      a missing or unreadable file, their diagnostics name the new filename, and neither takes a
      YAML dependency.
      *(traces: FR-7, C-3)*
- [ ] **SP-12 (migration of on-disk works).** Given a repository with legacy-format works across
      one or more worktree roots, covering both layouts, when the format migration runs, then
      every in-scope `STATE.md` is replaced by a `STATE.yml` preserving every scalar, every table
      row and every Q&A entry; the `.md` is gone; a second run changes nothing (for a fully
      converted work -- a file the DERIVED guard refused is converted on the re-run once its
      DERIVED row is resolved, per `§L-6` step 2); the repo format
      stamp advances; `enumerate-works.sh` reports the same values as before; both twins render
      every work with no `parse_warning`; and the Bash and PowerShell twins produce identical
      results on identical input.
      *(traces: FR-9, NFR-8, AC-8)*
- [ ] **SP-13 (review exclusion, surface and grading).** Given a per-delivery or per-task review
      dispatch, when `{{ARTIFACTS}}` is derived, then no state file appears in it -- enforced by
      the exclusion rule and filter at the single upstream point, by the per-skill brief no
      longer naming a state row as reviewed content, and by a test in the shape of the existing
      KB review-surface test. Given a completed cycle whose diff includes state churn, when the
      ledger is graded, then no ledger row cites a state file as its `Doc`, the grade equals the
      grade the same review produces without that churn, and `grade.sh` is unmodified.
      *(traces: FR-10a-d, A-3, AC-6, AC-7)*
- [ ] **SP-14 (render and fork integrity).** Given the canonical edits are complete, when the
      profile generator runs and the dogfood trees are resynced, then the dogfood byte-identity
      and multitool-isolation suites pass, all five profile renders carry the change, no render
      was hand-edited, and the deliberate `dashboard/scripts/` fork still accepts `Deploy` as a
      `Phase` value -- proving it was hand-updated, not resynced.
      *(traces: FR-12, FR-4d, NFR-7, C-1, C-2, AC-10)*
- [ ] **SP-15 (documentation *and consumer* truth).** Given the refactor is complete, when
      `STATE.md` and the retired markdown section headings are searched for across **every KB doc,
      skill, template, agent-context file, profile render, dogfood tree, and every operational
      consumer under `dashboard/`** -- specifically `dashboard/scripts/` (the
      `delete-pipeline.sh` guard and the `writeback-state.sh` fork), `dashboard/server/`
      (`server.mjs`, `server.py`, `reader.mjs`) and `dashboard/home.html` -- then no surviving
      reference describes an in-scope work-tree state file as markdown or as a reviewable artifact,
      no surviving reference *resolves a path to one*, and every remaining `STATE.md` occurrence is
      either the out-of-scope discovery-area ledger (`join(kbDir, ...)`, `SKIP_NAMES`) or an
      explicitly labelled legacy/migration reference. No KB doc names this work or its folder path.
      The `dashboard/` half of the surface is stated explicitly because a docs-and-renders-only
      search does not reach `§L-10` or `§L-11`: neither
      lives in a doc, a skill, a template or a render.
      *(traces: FR-8, FR-11, FR-4e, FR-7a, C-7, AC-11, AC-13)*
- [ ] **SP-16 (behavior preservation).** Given the pre-refactor per-test pass/fail set is
      recorded as a baseline from each suite's own summary line, when the same suites run on the
      post-refactor tree, then the set matches the baseline exactly except for tests enumerated
      in the change-set as intended format-asserting updates; any other newly-failing test, and
      any newly-*passing* test not on that list, is a regression. The coverage baseline is
      re-bootstrapped rather than row-edited, because the change is corpus-wide.
      *(traces: FR-13, AC-1, and the §1 behavior-preservation family slot)*
- [ ] **SP-17 (dependency floor).** Given the post-refactor tree, when both reader twins run in
      a clean environment with no third-party packages installed, then both parse state files
      successfully, and the Python and Node dependency manifests are unchanged.
      *(traces: FR-6, C-3, AC-12)*
- [ ] **SP-18 (self-hosting sequencing).** Given this refactor is delivered inside AID's own
      repository, when each stage lands, then the readers and the CLI accept the new format
      *before* any live work tree is converted, this work's own state remains writable and
      readable at every step in whichever format is live at that moment, and no step leaves the
      repository with works in two formats at the end of that step.
      *(traces: C-6, FR-9, and the ordering in §10 Priority)*
- [ ] **SP-19 (the two operational consumer layers keep working).** Both properties are
      behavioral, because both layers fail *silently* on a textual miss:
      (a) given a converted work whose `STATE.yml` carries `lifecycle: Running`, when
      `dashboard/scripts/delete-pipeline.sh` runs against it, then it refuses and exits 7 --
      proving the rename did not turn the guard into a no-op (`§L-10`); and (b) given a converted
      work, when each of the three write-enabled dashboard server edit surfaces (task set-notes,
      pipeline `Lifecycle=Completed`, task rename) is exercised, then the write succeeds against
      `STATE.yml` in **both** server runtimes with identical results, and the raw-state viewer
      resolves the same source path in both (`§L-11`).
      *(traces: FR-7a, FR-4e, AC-13, C-4)*
- [ ] **SP-20 (template shape -- the two mechanical rules `§L-1` makes normative).** Given the
      three converted templates (`work-state-template.yml`, `delivery-state-template.yml`,
      `task-state-template.yml`), when each is inspected, then **(a)** no writer-owned key carries
      a **trailing inline comment** -- every zone note, enum hint and single-writer annotation is a
      full-line comment *above* its key -- and **(b)** no key whose real value must be readable
      before the first write carries an un-instantiated `{...}` placeholder. Both are greps, not
      judgments, which is why they belong in a gate rather than in review prose. Rule (a)'s
      mechanism: `WB_SET_FRONTMATTER_AWK` replaces the **entire** line for the key it writes
      (`writeback-state.sh:619`), so a trailing comment on a writer-owned key is destroyed on the
      first write -- silently, and only for the keys that happen to have been written yet. Rule
      (b)'s mechanism: the readers' placeholder skip (`_looks_like_unfilled_placeholder`,
      `state_schema.py:82`) is the safety net that keeps a leaked placeholder from being rendered
      as data, not a licence to ship one. Neither is hypothetical -- today's
      `work-state-template.md` violates (a) on `pause_reason` (`:12`), `block_reason` (`:13`),
      `block_artifact` (`:14`), `ticket_ref` (`:15`) and `pipeline.path` / `pipeline.initiator`
      (`:3-4`), so this is a recurrence risk carried in the source being converted, and `§D-4`'s
      target skeletons are the corrected form. Asserted by
      `tests/canonical/test-work-state-template.sh` against the templates `task-002` delivers
      (`task-015` retargets the suite).
      *(traces: FR-3, FR-2b, AC-9)*

---

## Technical Specification

> Authored by the SPEC state of `/aid-refactor` (shortcut engine), which collapses Define +
> Specify. Section activation per
> `shortcut-scaffolding/change-refactor.md § aid-refactor -- SPEC section activation`: the
> mandatory three only. `refactor-kind` is `restructure`, so no conditional section is
> activated -- explicitly including `### Migration Plan`, whose substance lives in
> `### Layers & Components §L-6` instead, because for this family the modules touched *are*
> the migration.

### Data Model

**The ruling on "unchanged".** The family default for a `restructure` is that this section
reads "unchanged -- behavior-preserving refactor". That default is **half true here, and
writing it bare would be false.** The distinction that resolves it:

| Layer | Verdict | Evidence |
|---|---|---|
| **State model** -- the set of fields, their meaning, their closed enums, the zone/writer assignment, the single-writer and disjoint-write rules, most-advanced-wins reconcile ordering | **Unchanged.** No field added, renamed or removed; no enum widened or narrowed. This is what makes the refactor behavior-preserving and is asserted by SP-2. | `REQUIREMENTS.md §4 Out of Scope` ("no new field, no removed field, no widened or narrowed enum"); the ordering comment block in `canonical/aid/templates/work-state-template.md:62-86`, which stays the single encoding of that ordering |
| **Serialization** -- the filename, the container, the on-disk grammar the writer emits and the readers parse | **Changed. This is the whole point of the work.** A markdown document with a YAML frontmatter block plus five authored markdown table/bullet sections becomes one YAML document. Seven in-scope `STATE.md` join sites in the Node reader twin (plus the Python twin's own constants), four awk programs in the writer, three shell readers, the two dashboard server runtimes, three templates and the CLI migration engine all bind to this layer. | `writeback-state.sh:563` (`WB_SET_FRONTMATTER_AWK`), `:915` (positional table awk, `col_idx=3..7`), `:1056` and `:1259` (the **two** section-replace awks); `dashboard/reader/parsers.py:1246-1252` (the seven section regexes); `dashboard/server/reader.mjs:1648` (`hasTableSep`) |

So: **the data model is unchanged; the data *format* is entirely replaced.** Everything below
specifies the new serialization and asserts the model identity across it. A reviewer checking
this section should check SP-2 (identity) and SP-3 (DERIVED absent but not lost), not look for
new entities.

There is no database, no ORM and no `.aid/knowledge/schemas.md` entity in play -- AID's
persistence is files. The authoritative schema doc is
`.aid/knowledge/artifact-schemas.md § State-File Hierarchy` / `§ Work STATE.md` /
`§ Delivery STATE.md` / `§ Task STATE.md`, and FR-11 updates exactly those sections plus that
doc's validation-points table.

#### D-1. Filename and container

`STATE.yml` -- `.yml`, not `.yaml`, matching `.aid/settings.yml` (C-9, A-1). A-1 flagged that
the exact string was never separately confirmed; it is **settled here as a design decision**,
on two pieces of repo evidence rather than preference: the project's only other YAML data file
is `.aid/settings.yml`, and the reader twins' settings parsers are keyed to that extension.
Confirmable at the GATE/APPROVAL step at zero cost, because the string appears in exactly one
canonical constant per consumer (`### Layers & Components`).

The file is a **single YAML document with no `---` document fence**. The leading fence exists
today only to delimit frontmatter from markdown body; with no body there is nothing to
delimit, and keeping a bare `---` would leave both twins' fence-state machines alive for no
reason. Consequence for the writer: what is today "the frontmatter region between the first
two `---` lines" becomes "the whole file", and the synthesize-a-block-when-absent branch
(`writeback-state.sh:581-595`) collapses into create-file-if-absent.

#### D-2. The three zones, mapped

| Zone (per `work-state-template.md:26-42`) | Was | Becomes |
|---|---|---|
| **FRONTMATTER** (machine scalars) | the leading `---` YAML block | **top-level keys, verbatim.** Same names, same one-level nesting (`pipeline.path`, `pipeline.initiator`), same enum strings byte-for-byte. Lifted, not rewritten (A-2, C-5) |
| **AUTHORED** (markdown body) | `## Interview State` table, `## Lifecycle History` table, `## Deploy State` table, `## Delivery Lifecycle` bullets, `### Tasks lifecycle` table, `## Delivery Gate` bullets, `## Quick Check Findings` bullets, `## Cross-phase Q&A` blocks, `## Dispatch Log` table | **YAML structures** under the keys in D-4, one key per former section (FR-2b). The templates' enum hints and single-writer annotations survive as full-line YAML comments -- the reason YAML beat JSON (§1) |
| **DERIVED** (read-time union) | `_none yet_` placeholder tables that exist to be ignored | **absent from disk.** No key at all (FR-2c). A reader seeing no key derives the same union it derives today. `Cross-phase Q&A` is the one exception: it keeps a key, because on the flattened Lite path it is AUTHORED (`artifact-schemas.md § Work STATE.md`) |

**A-4 settled, with a guard.** A-4 assumed no consumer reads a DERIVED section from the parent
file. Verified, with a caveat worth naming: both twins *do* have parsers for work-level
`## Tasks State`, `## Features State`, `## Plan / Deliveries`, `## Triage`,
`## Quick Check Findings` and `## Delivery Gates`
(`parsers.py:1246-1252`, `:2267`, `:2342`, `:2386`, `:2664`, `:2747`; the same set in
`reader.mjs`). They are **legacy monolithic-era readers**: against a current-template work they
find only the `_none yet_` placeholder, which `_parse_tasks_line` explicitly skips
(`parsers.py:2295-2297`), so they contribute nothing. A-4 therefore holds for every
current-shape work -- and the converter enforces it: a DERIVED section holding a real row makes the
converter **refuse that file** (helper returns non-zero naming file and section; the `STATE.md`
stays; the step WARNs), never a silent drop (SP-3), with the remedy being to run the
monolithic-to-hierarchy migration first and re-run `aid update` (`§L-6` step 2). A-4 is settled as true, with that guard as
its enforcement.

#### D-3. The permitted YAML subset, and the parsing strategy

**Ruling: hand-rolled parser, extended from the pair that already exists -- not a new parser,
and not a vendored library.**

Two hard repo constraints make the decision, and neither is negotiable at this layer.
`packages/pypi/pyproject.toml` declares `dependencies = []`, and the root `package.json`
dependency block is version-tracking only, never installed from (FR-6, C-3). And the twins
already hand-parse: `dashboard/reader/state_schema.py:116` `parse_frontmatter_scalars` and
`dashboard/server/reader.mjs:173` `parseFrontmatterScalars` are a matched pair handling flat
scalars plus one level of nesting, with quote-stripping (`_strip_scalar_quotes`,
`state_schema.py:63`) and placeholder rejection. `state_schema.py:19-27` states the posture
outright: the frontmatter is "a deliberately restricted subset ... so a small hand-rolled
scanner stands in for a real YAML parser".

So the work is **extend that pair**, not write a parser. The extension is: block sequences,
mappings-of-mappings, the two escape modes in D-5, and full-line/inline comment handling.
Bounded, and bounded *because the subset is declared and violations are rejected rather than
guessed at*.

**The alternative I rejected, and its cost.** Vendoring a YAML parser per runtime under the
existing `vendor/` convention. Rejected for three reasons, any one sufficient: (a) it doubles
the vendored third-party surface (two trees, two licences, two refresh paths) on a project
whose install-time dependency floor is deliberately zero; (b) it makes the twins' YAML
*version* semantics differ -- PyYAML defaults to the 1.1 resolver, js-yaml to the 1.2 core
schema -- which is precisely the `yes`/`no` divergence already recorded at
`dashboard/reader/state_schema.py:229-239`, so a library would *amplify* NFR-2 instead of
retiring it; (c) a real parser accepts constructs the schema never needs (anchors, tags, flow
collections, multi-document streams), widening the input surface both twins must agree on. A
declared subset with an explicit reject list is a *smaller* parity surface than a full parser,
not a larger one.

**Permitted shapes.** Exactly five, indentation two spaces per level, no tabs:

| Shape | Form | Used by |
|---|---|---|
| **S1** scalar | `key: value` at column 0 | every former frontmatter scalar |
| **S2** mapping of scalars | `key:` then 2-space `child: value` | `pipeline`, `interview` (head), `delivery_lifecycle`, `delivery_gate`, `quick_check` (head) |
| **S3** mapping of mappings | `key:` then 2-space `id:` then 4-space `child: value` | `tasks_lifecycle` (keyed by `task-NNN`) |
| **S4** sequence of flat mappings | `key:` then 2-space `- first: v` then 4-space `next: v` | `lifecycle_history`, `deploy`, `qa` |
| **S5** nested sequence | 2-space `child:` then 4-space `- first: v` / 6-space `next: v`, or a sequence of scalars | `interview.sections`, `quick_check.findings`, `delivery_gate.issue_list` |

An empty collection is written `[]` (sequence) or `{}` (mapping); an absent key is
semantically identical to an empty collection, and readers must treat the two the same.

**A parser must reject** -- meaning: emit a `parse_warning` naming file, line and construct,
skip exactly that key, keep parsing, and never raise (FR-5 graceful degradation, SP-1):

| Rejected | Why |
|---|---|
| tab characters in indentation | not indentation in YAML at all; a silent-corruption class |
| flow collections other than the literal `[]` / `{}` (`[a, b]`, `{a: b}`) | needs a tokenizer; no schema key requires it |
| block scalars -- the literal (bar) and folded (`>`) indicators, with any chomping suffix | multi-line values use D-5 double-quote escaping instead |
| anchors `&`, aliases `*`, tags `!`, directives `%` | no state value is ever shared or typed |
| a second document (`---` or `...` at column 0) | one file, one document (D-1) |
| indentation not a multiple of two, or nesting deeper than S5 | the reject that keeps the parser small |
| a non-comment, non-blank line that is neither a `key:` line nor a sequence entry (a `- `-prefixed item, whether `- value` or `- key: value`) | malformed. **Scoped deliberately:** a bare `- value` scalar item is *permitted*, because S5's "sequence of scalars" form is what `delivery_gate.issue_list` uses -- rejecting every separator-less line would drop every gate issue entry. It is the line that is neither of those two shapes that is malformed |
| a duplicate key at the same level | last wins **and** warn -- specified so both twins agree rather than diverging by dict semantics |
| a byte-order mark | stripped, warned (Windows editors add it) |

**Nesting depth** is therefore capped at three levels of mapping (S3) or a sequence at the
second level (S5). Nothing in D-4 needs more.

**Comments.** Full-line `#` comments at any indentation are **preserved by the writer and
skipped by readers**. This already works: the live work file carries two of them inside its
frontmatter block, and both twins' scanners fall through them
(`state_schema.py:182-185` -- a `#` line fails the key regex and is skipped). Trailing inline
comments are **permitted only on a line the writer will never rewrite, and forbidden on any
key the writer may write.** The reason is mechanical, not stylistic:
`WB_SET_FRONTMATTER_AWK` replaces the *entire* line for the key it writes
(`writeback-state.sh:619`), so a trailing comment on a written key is destroyed on first
write. The templates therefore put every enum hint on its own full-line comment *above* the
key. Independently, readers must gain inline-comment stripping on this path: today
`parse_frontmatter_scalars` calls only `_strip_scalar_quotes` (`state_schema.py:194`) and does
**not** strip a trailing `#` comment -- a real gap, currently masked because every commented
template key is also a placeholder and gets skipped. Close it by applying the existing
`_strip_yaml_inline_comment` idiom (`parsers.py:304`, `reader.mjs:565`), which already handles
the quoted-value case, to the state path in both twins.

#### D-4. The concrete target shapes

**Work-level `STATE.yml`, flattened Lite layout** (the layout of this very work). Comments
shown are the real template comments, abbreviated.

**Every annotation is a full-line comment *above* its key -- no trailing inline comments
anywhere in these skeletons.** That is not a stylistic preference; it is D-3's mechanical rule
made concrete, and it is the shape L-1 requires the templates to obey.
`WB_SET_FRONTMATTER_AWK` replaces the *entire* line for the key it writes
(`writeback-state.sh:619`), so a trailing comment on a writer-owned key is destroyed on the first
write -- meaning a template that carried one would silently lose its own documentation the first
time the pipeline ran. Applied uniformly (including to `[A]` keys) rather than only to today's
`[W]` set, so that widening the writer's key set later cannot reintroduce the defect:

```yaml
# Work State -- work-NNN-{name}
# Every key below is machine data. Writer legend -- stated in full-line comments
# above each key, NEVER as a trailing comment on the key itself (D-3):
#   [W] writeback-state.sh is the sole writer (surgical single-key write)
#   [A] authored by this work's active branch (single writer)
# DERIVED views (features, deliveries, tasks rollup, delivery gates, calibration
# log, dispatches) are NOT represented here -- they are read-time unions over
# child files. Never add them.

# [W]
#   path: lite | full
#   initiator: aid-describe | aid-{shortcut-skill}
pipeline:
  path: lite
  initiator: aid-refactor
# [W]
started: '2026-08-12'
# [W] resolved from .aid/settings.yml
minimum_grade: A
# [W] 'yes' | 'no' -- quoted, see NFR-2 / D-5
user_approved: 'no'
# [W] Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
lifecycle: Running
# [W] Describe | Define | Specify | Plan | Detail | Execute
phase: Specify
# [W] aid-{skill} | none
active_skill: aid-refactor
# [W]
updated: '2026-08-12T15:12:00Z'
# [W] set only when lifecycle = Paused-Awaiting-Input
pause_reason: --
# [W] set only when lifecycle = Blocked
block_reason: --
# [W]
block_artifact: --
# [W] {connector-stem}:{external-id} | --
ticket_ref: --

# Flattened single-delivery works only -- omit these 4 keys for full works.
# [W] Pending-Spec | Specified | Executing | Gated | Done | Blocked
delivery_state: Pending-Spec
# [W] Small | Medium | Large
gate_tier: Small
# [W]
gate_grade: Pending
# [W]
gate_timestamp: --

# [A] aid-describe
#   state: In Progress | Complete | Approved
#   sections[].state: Pending | Complete
interview:
  state: In Progress
  grade: Pending
  sections:
    - id: 1
      name: Objective
      state: Complete
      updated: '2026-08-12'

# [A] append-only audit trail, newest LAST
lifecycle_history:
  - date: '2026-08-12'
    event: Work created
    grade: --
    notes: Initial scaffold by aid-config

# [A] aid-deploy only; one entry per delivery:
#   - delivery / state / pr / kb_updated / tag / notes
deploy: []

# [A] flattened only; `updated` is a writer-targeted child key (L-2)
delivery_lifecycle:
  updated: '2026-08-12T15:12:00Z'
  block_reason: --
  block_artifact: --

# [W] flattened only -- one entry per task
#   state: Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
tasks_lifecycle:
  task-001:
    state: Pending
    review: --
    elapsed: --
    notes: --
    display_name: --

# [A] flattened only; `issue_list` is a writer-targeted child key (--append-issue, L-2)
#   issue_list: severity-tagged strings, or [] when the gate passed clean
delivery_gate:
  issue_list: []

# [A] flattened Lite only (AUTHORED here, not derived); one entry per question:
#   - id / category / impact / state / context / suggested / answer / applied_to
qa: []
```

**Work-level, full layout:** identical minus the four flattened-only gate/delivery scalars,
minus `delivery_lifecycle` / `tasks_lifecycle` / `delivery_gate` (each lives in its own
delivery/task file), and minus `qa` (DERIVED on the full path). Exactly the omission rule the
current template already states.

**Per-delivery `deliveries/delivery-NNN/STATE.yml`** (full path only):

```yaml
# Delivery State -- delivery-NNN   (single writer: this delivery's branch)
# [W] Pending-Spec | Specified | Executing | Gated | Done | Blocked
delivery_state: Pending-Spec
# [W] Small | Medium | Large
gate_tier: Small
# [W]
gate_grade: Pending
# [W]
gate_timestamp: --
# [W] {connector-stem}:{external-id} | --
ticket_ref: --
# [A]; `updated` is a writer-targeted child key (L-2)
delivery_lifecycle:
  updated: '2026-08-12T15:12:00Z'
  block_reason: --
  block_artifact: --
# [A]; `issue_list` is a writer-targeted child key (L-2)
delivery_gate:
  issue_list: []
# [A] delivery-scoped Q&A -- entries as in the work file
qa: []
# DERIVED: tasks rollup is a read-time union over tasks/task-NNN/STATE.yml. Not represented.
```

**Per-task `deliveries/delivery-NNN/tasks/task-NNN/STATE.yml`** (full path only):

```yaml
# Task State -- task-NNN   (single writer: the delivery branch that owns this task)
# [W] Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
state: Pending
# [W]
review: --
# [W] HH:MM | --
elapsed: --
# [W]
notes: --
# [W] mutable display-name override (writeback-state.sh:829)
display_name: --
# [W] {connector-stem}:{external-id} | --
ticket_ref: --
# [W] --findings
#   findings entries: - severity / description / source / disposition
quick_check:
  reviewer_tier: Small
  findings: []
# [A] - date / agent / eta_band / actual / outcome
dispatch_log: []
```

Note on the task file: `quick_check` and `dispatch_log` exist **only** at this level. The
flattened Lite path has no per-task state file and no `--findings` write path today
(`mode_findings` resolves a per-task file unconditionally, `writeback-state.sh:1035-1040`), so
inventing a work-level `quick_check` key would be a model change and is out of scope. The two
work-level detail-view parsers that scan for those sections (`parsers.py:2664`, `:2747`) are
retargeted to the corresponding keys and continue to return the same empty result for a
current-shape work -- behavior preserved, including the pre-existing staleness, which `§L-12`
records rather than fixes.

#### D-5. Quoting, and the implicit-typing rule (NFR-2)

Three emission modes, decided per value by the writer, in this order:

1. **Bare** iff the value matches `^[A-Za-z0-9_.+/-]+$` (the class the writer already uses,
   `writeback-state.sh:568`) **and** is not on the implicit-type deny list below. Keeps
   `lifecycle: Running`, `gate_grade: A+`, `pause_reason: --` byte-identical to today.
2. **Single-quoted**, doubling an embedded `'`, when quoting is needed and the value has no
   newline or control character. Already the writer's behavior and already inverted by
   `_strip_scalar_quotes`. This is what makes the FR-4b pipe case work with no new code:
   `|` is not in the bare class, so a value containing it is single-quoted and round-trips --
   the two guards at `writeback-state.sh:767-774` are simply deleted, not replaced.
3. **Double-quoted with a five-escape subset** (`\"`, `\\`, `\n`, `\r`, `\t`) iff the value
   contains a newline or a control character -- the only case single-quote style cannot
   express. Both twins gain the inverse unescape; any *other* backslash escape (`\uXXXX`,
   `\x41`) is rejected per D-3 with a warning and literal passthrough. This is the one new
   quoting mode, and it exists solely to satisfy FR-4b for newline-bearing values; no current
   caller produces one, so it adds no byte churn.

**Implicit-type deny list -- always quoted, never bare** (NFR-2): `y`, `Y`, `yes`, `Yes`,
`YES`, `n`, `N`, `no`, `No`, `NO`, `true`, `True`, `TRUE`, `false`, `False`, `FALSE`, `on`,
`On`, `ON`, `off`, `Off`, `OFF`, `null`, `Null`, `NULL`, `~`, the empty string, anything
matching a number (`^[-+]?[0-9]`), and anything matching an ISO date or date-time. Rationale
and evidence: the live work file on disk right now carries `user_approved: no` bare -- the
exact PyYAML-1.1-versus-js-yaml-1.2 divergence documented at
`dashboard/reader/state_schema.py:229-239`. Quoting it (`user_approved: 'no'`) keeps the enum
*string* `no` intact (C-5, A-2: no enum value changes) while making the on-disk form
version-independent. Timestamps already fall out correctly: `updated` contains a `:`, so it is
not bare-class and is already single-quoted on disk today. `parse_bool_yesno`
(`state_schema.py:226`) keeps accepting all four literals, per NFR-2's tolerance clause, for a
file a third-party tool re-dumped. Readers accept either quote style on read; the writer emits
single-quote style.

**A-6 settled:** every value in play is a short scalar, an enum token, an ISO timestamp, a
path, or a one-line note -- all expressible in this subset. With mode 3 above, even a
newline-bearing note is expressible, so A-6's residual risk drops to zero rather than being
carried.

#### D-6. What is *not* in the data model

Restating the boundary so no downstream task widens it: the discovery-area ledger
`.aid/knowledge/STATE.md` stays markdown and stays a KB document (out of scope, three
independent reasons in `REQUIREMENTS.md §4`); `.aid/.temp/HOUSEKEEP_STATE_*.md` and the
control-signal/heartbeat files are untouched; `REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`,
`BLUEPRINT.md` and `DETAIL.md` stay markdown and stay reviewable; no JSON Schema artifact and
no CI schema-validation gate is added (A-5); and no rollup is ever persisted into a parent
file (C-8).

### Feature Flow

**Unchanged -- behavior-preserving refactor.** There is no request/response path here: AID's
state layer is local files with one writer and several readers, and the *sequence* of
operations is identical before and after. Recorded explicitly, because "the flow is unchanged"
is itself an acceptance property (SP-4, SP-6, SP-10), not an absence of content:

- **Write flow (unchanged in every step):** resolve target file (env override -> layout
  auto-detect -> path resolution) -> validate field name and closed enum -> acquire the
  sentinel lock (`set -o noclobber` atomic create, 0.5 s sleep-poll, `AID_LOCK_TIMEOUT`
  retries, exit 2 on contention, `writeback-state.sh:506-526`) -> compute new bytes to a temp
  file -> verify (non-empty **and** target key present) -> atomic `mv` -> release lock via the
  `EXIT` trap. Every `die` path still leaves the original file untouched. What changes is only
  the "compute new bytes" step's internals.
- **Read flow (unchanged):** enumerate worktree roots -> enumerate work dirs -> **one** read
  per work state file -> parse -> build the model -> derive the read-time unions -> reconcile
  most-advanced-wins across branches. Still one read (`reader.py` step 5a, reused by
  `read_repo_detail` for `raw_state`, `reader.py:696-713`), still bounded
  (`io_bounds.py`, `MAX_READ_BYTES`), still `parse_warning`-not-throw.
- **Reviewer flow (one step removed):** derive `{{ARTIFACTS}}` from disk -> **filter out state
  files (new)** -> dispatch -> ledger -> `grade.sh`. Nothing else in the loop moves;
  `grade.sh` is not touched (verified: it carries zero `STATE` references).

The one **genuinely new sequence** is migration, and it reuses an existing engine rather than
adding a path: `aid <cmd>` -> `_aid_format_gate` compares the repo's format stamp to
`AID_SUPPORTED_FORMAT` -> older repo prints `WARN: ... Run: aid update` (or is silent under
`AID_NO_MIGRATE=1`) -> `aid update` -> `_aid_migrate_repo` runs its ordered WARN-not-fail steps,
**with the state-format conversion appended as a new step** -> stamp advances. Detailed in
`§L-6`.

### Layers & Components

This is where the restructure lives. **Eleven components -- L-1 .. L-11** -- each with its current
shape, its target shape, and what enforces the change. `§L-12` is **not** a component: it is the
carry-forward register for open items and findings routed onward.

Numbering note: L-10 and L-11 are appended rather than slotted into
dependency order (L-10 belongs logically beside `§L-5`, L-11 beside `§L-4`) so that every existing
citation to L-1 .. L-9 stays valid; the open-items register is `§L-12`.

#### L-1. Templates (FR-3 -- do first, everything binds to them)

`canonical/aid/templates/work-state-template.md`, `delivery-state-template.md`,
`task-state-template.md` become `work-state-template.yml`, `delivery-state-template.yml`,
`task-state-template.yml`, carrying the D-4 skeletons with the current zone documentation,
enum hints, ordering block and single-writer notes as full-line YAML comments.
`discovery-state-template.md` is untouched (out of scope). Two shape rules the templates must
obey, both mechanical: no trailing inline comment on any writer-owned key (D-3), and no
un-instantiated `{...}` placeholder on a key whose real value must be readable before the
first write -- the readers' placeholder-skip logic (`_looks_like_unfilled_placeholder`,
`state_schema.py:82`) stays as the safety net, unchanged. Both rules are asserted by **SP-20**,
which exists because they are grep-checkable and because the templates being converted violate
the first one today (`work-state-template.md:3-4`, `:12-15`).

Consumers of the templates that copy them by name: `shortcut-engine.md § INTAKE Step 4`,
`aid-review/SKILL.md`, and the CLI/scaffold paths -- all updated in L-7.

#### L-2. Writer: `canonical/aid/scripts/execute/writeback-state.sh`

Four awk programs collapse to one, and the CLI surface does not move (SP-5). Four, not three:
`WB_SET_FRONTMATTER_AWK` is one program used from two call sites (`:719`, `:725`), and the
section-replace logic is **two** separate program bodies (`:1056` findings, `:1259` delivery
gate), not one reused body -- so the table's three rows below cover four awk programs.

| Today | Target |
|---|---|
| `WB_SET_FRONTMATTER_AWK` (`:563-655`) -- rewrites one key inside the leading `---` block; synthesizes a block when absent; body reproduced byte-for-byte | **The single write path.** Same algorithm, with the fence state machine removed: the whole file is the key space. `parent`/`child` dotted-key handling (`pipeline.path`) is retained as-is, and extended to the S3/S4/S5 paths a write can target (`tasks_lifecycle.task-NNN.state`, `delivery_lifecycle.updated`, `delivery_gate.issue_list`, `quick_check.*`) -- create-parent-if-absent, insert-at-end-of-parent, exactly as the existing `parent_seen` logic already does one level up |
| `write_task_field_flat` (`:877-1022`) -- 146 lines of positional table arithmetic (the embedded awk body alone is `:915-1008`), `col_idx=3..7`, header/separator/placeholder-row handling, `_none yet_` replacement, row append | **Deleted.** A flattened per-task field write becomes the same single-key write against `tasks_lifecycle.task-NNN.<field>`. The `col_idx` map, the `new_row()` builder, `maybe_insert()`, `last_was_row`, the legacy-5-column tolerance and the `task-NNN` row-presence grep sanity check all disappear with it -- this is the single largest deletion in the work, and the clearest evidence the rationale is real |
| Section-replace awk, twice (`:1056-1081` findings, `:1259-1284` delivery gate) -- replace a `##` section's body, stopping at the next `##` or a bare `---` | **Deleted.** Both become structured writes: `quick_check` (mapping + sequence) and `delivery_gate.issue_list` (sequence). The "must not swallow the trailing `---` separator" hazard both programs were written to avoid ceases to exist |

Preserved verbatim, and asserted by SP-5/SP-6: the mode dispatch and every flag;
`AID_STATE_FILE` / `AID_WORK_DIR` / `AID_DELIVERY_DIR` / `AID_TASK_STATE_FILE` /
`AID_DELIVERY_STATE_FILE` / `AID_ISSUES_DIR` / `AID_LOCK_TIMEOUT`; the exit codes 0-6
(including 6 for a malformed file -- the presence check moves from "the `## Task State`
heading exists" to "the file parses and is a mapping"); every closed-enum validation in
`mode_field`, `mode_pipeline`, `mode_delivery_lifecycle` and `mode_gate_field`; the
conditional-field clearing on a `Lifecycle` change (`:1491-1512`) including its
chained-temp-file idiom; the sentinel lock; write-to-temp + verify + atomic `mv`;
`ENVIRON`-based raw-value passing (never awk `-v`, which re-processes escapes -- the fix at
`:542-548` and `:908-914` must not regress); and the CRLF / trailing-newline guards
(`has_crlf`, `had_trailing_nl`, `:707-737`, FR-4c, NFR-4).

Two deliberate deletions beyond the awk collapse: the `|` guard (`:767-769`) and the newline
guard in `mode_field` (`:772-774`) -- FR-4b. `mode_pipeline`'s newline guard (`:1420-1422`)
also goes, since D-5 mode 3 can express it. `wb_frontmatter_verify` (`:746`) generalizes to
"the written key resolves to the written value on re-read", which is a *stronger* check than
today's `grep -q "^key:"` and closes the nested-key blind spot (today it greps
`^  child:` for any parent).

**FR-4a restated for a one-zone file:** "body byte-invariance" no longer parses, because there
is no body. The property becomes: *every **pre-existing** line other than the written key's own
line is reproduced byte-for-byte* -- including full-line comments, blank lines, key order and the
absence/presence of a trailing newline. That is what SP-4 asserts. It is testable as a one-line
`git diff` **when the written key already exists**; when the write targets a nested key whose
parent mapping is absent, the writer's existing `create-parent-if-absent` behavior legitimately
adds two lines (the parent key line plus the indented child line, printed by the closing-fence
flush rule `:597-615` -- its parent-absent branch `:606-610`, guarded by `!parent_seen`), and the
property still holds because no pre-existing line moved. Note that the *other* branch that emits
a parent-plus-child pair, the `NR == 1` no-frontmatter-present rule (`:581-595`, whose
`:585-589` synthesizes a whole block), is **not** the relevant one: `§D-1` retires it into
create-file-if-absent, so citing it for this property would point at code being deleted. Writing the first `tasks_lifecycle.task-NNN.state`
for a newly-added task is precisely that case, so the two-line form is the normal path, not an
edge case -- which is why the byte-invariance, not the diff line count, is the assertion.

**Render surface (FR-12, C-1, C-2):** **seven** renders exist -- five profiles
(`profiles/antigravity`, `profiles/claude-code`, `profiles/codex`, `profiles/copilot-cli`,
`profiles/cursor`) plus this repo's `.claude/` and `.cursor/` dogfood trees -- and the file's own
banner (`:3-34`) says the canonical copy is the only edit point. That banner also says
"EIGHT RENDERS EXIST", which is **stale in the shipped script**; whichever task rewrites that
banner region corrects it. Plus one non-render: `dashboard/scripts/writeback-state.sh`
is a **deliberate fork** that additionally accepts `Deploy` as a `Phase` value; it is
hand-updated and never resynced, and SP-14 asserts the `Deploy` acceptance survives, which is
the only available proof it was not overwritten (no test guards this -- C-2).

#### L-3. Reader twin A: `dashboard/reader/` (Python)

| Function | Target |
|---|---|
| `state_schema.parse_frontmatter_scalars` (`:116`) | **Extended into the single state parser** (D-3): S1-S5, both escape modes, inline-comment stripping, the reject list with warnings. Renamed to reflect that it now parses a whole document, not a frontmatter block |
| `parsers.parse_state_md` (`:1282`) | Section state machine deleted (`in_pipeline_status`, `in_tasks`, `in_crossphase`, `in_triage`, `in_features`, `in_deliveries`, `in_lifecycle_history` and their seven regexes at `:1246-1252`). Becomes: parse document -> map keys onto `ParsedWork`. `_apply_pipeline_frontmatter` (`:2166`) / `_apply_identity_frontmatter` (`:2211`) become the whole of it |
| `_parse_tasks_line` (`:2267`), `_parse_features_line` (`:2342`), `_parse_deliveries_line` (`:2386`), `_parse_lifecycle_history_line` (`:2441`), `_parse_pipeline_status_line` (`:2108`), `_parse_triage_line` (`:2325`) | **Deleted.** Positional-column readers of DERIVED or legacy sections; nothing to retarget (D-2, SP-3) |
| `parse_tasks_lifecycle_md` (`:2003`) | Becomes a `tasks_lifecycle` mapping read; the `ParsedTaskState` return shape is unchanged so `reader.py:1132` needs no change |
| `parse_task_state_md` (`:1637`), `parse_delivery_state_md` (`:1740`) | Frontmatter-first already; drop their prose fallbacks, add `quick_check` / `dispatch_log` / `delivery_lifecycle` / `delivery_gate` / `qa` structured reads |
| `parse_quick_check_findings` (`:2664`), `parse_delivery_gate` (`:2747`) | Retargeted to keys; still return empty for a current-shape work (D-4 note) |
| `parse_header_bold_field` (`state_schema.py:201`) and the legacy-prose fallback callers | **Deleted for state files.** Replaced by one legacy *detector*: a sibling `STATE.md` with no `STATE.yml` yields `_minimal_work_model` plus a `parse_warning` naming the migration command (SP-9, NFR-8). Note `parse_header_bold_field` may have non-state callers -- check before deleting the symbol; the *state* call sites are what go |
| `reader.py` filename constants (`:403`, `:833-834`, `:1069-1070`, `:992`, plus `_read_work_hierarchical`'s work-level (`:1273`), delivery-level (`:1360`) and task-level (`:1403`) resolutions) and the `state_path_label` strings (`:699`) | One constant per module, `STATE.yml`; the `.aid/works/{work}/STATE.yml` labels follow |
| `_detect_flat` (`reader.py:1002`), `_detect_hierarchy` (`:971`) | Filename only; the three-part rule is unchanged (SP-7) |
| `models.py`, `derivation.py`, `io_bounds.py` | Unchanged. The model is unchanged (D-1 ruling), derivation is unchanged (C-8), bounded reads apply to the new name unchanged (NFR-9) |

#### L-4. Reader twin B: `dashboard/server/reader.mjs` (Node)

The same change, function for function -- `parseFrontmatterScalars` (`:173`),
`parseStateText` (`:2308`), `parseTasksLifecycleMd` (`:3833`), `_parseTaskStateMd` (`:3502`),
`_parseDeliveryStateMd` (`:3589`), `parseQuickCheckFindings` (`:5038`), `parseDeliveryGate`
(`:5121`), `_detectFlat` (`:3428`), `_stripScalarQuotes` (`:137`),
`stripYamlInlineComment` (`:565`) -- plus two deletions with no Python counterpart:
`hasTableSep` (`:1648`), whose only job is telling a markdown header row from a separator row,
and `extractLatestHistoryDate` (`:1690`), which becomes `max(lifecycle_history[].date)`.
**Seven** in-scope `join(workDir, "STATE.md")` / `join(..., "STATE.md")` sites move to `STATE.yml`
(`:3062`, `:3416`, `:3986`, `:4189`, `:4272`, `:4321`, `:4710`) -- seven, and the eighth
`join(...)` site in the file (`:879`, `join(kbDir, "STATE.md")`) is explicitly out of scope, see
below. The Node twin also carries four **label** strings that must be retargeted with them
(`:3063`, `:3982`, `:4184`, `:5439`) -- the counterpart of the Python twin's `state_path_label`
strings named in `§L-3`; omitting them leaves the
Node dashboard displaying `STATE.md` paths for `STATE.yml` files.

**Two sites must NOT change** -- both are the out-of-scope discovery-area ledger:
`join(kbDir, "STATE.md")` (`:879`) and `SKIP_NAMES` (`:1528`), which excludes `STATE.md` from
the KB doc set. Editing either is a scope defect, and it is the single easiest mistake to make
in this work, because a blind find-and-replace hits both.

**Twin-parity contract (NFR-1, C-4) -- what enforces it.** `state_schema.py:29-32` already
states the rule ("the Node twin defines the SAME functions inline ... keep both in lockstep"),
and `architecture.md § Polyglot parity` states the general principle. Enforcement is not the
statement; it is these three, in order of strength:

1. **Cross-runtime fixture parity suites** -- the existing pattern: build a fixture, read it
   with `reader.py` and with `reader.mjs`, compare payloads field-by-field. Precedents:
   `dashboard/reader/tests/test_flattened_layout_parity.py` (which already asserts
   `reader.py` and `reader.mjs` "read the SAME fixture identically"),
   `test_resolve_work_dir_cross_runtime_parity.py`,
   `test_shortcut_kind_map_cross_runtime_parity.py`, `test_task066_kb_parity.py`,
   `dashboard/server/tests/test_task010_task_notes_cross_runtime_parity.py`. The new parse
   path extends this set (SP-8).
2. **A shared conformance corpus** -- one directory of small `.yml` inputs, each paired with
   its expected parse result: one file per permitted shape (S1-S5), one per rejected construct,
   one per quoting mode, one per implicit-typing literal. Both twins run the same corpus and
   must produce the same values and the same warning set. This is the parity surface reduced to
   data, so a divergence is a failing row rather than a silent field difference. It is also the
   only practical way to prove the reject list agrees.
3. **The lockstep comment**, kept current in both files. Necessary, not sufficient -- which is
   exactly why (1) and (2) exist.

#### L-5. Shell readers

`canonical/aid/scripts/works/enumerate-works.sh`: `state_file="$work_path/STATE.md"` (`:230`)
-> `STATE.yml`, and `_frontmatter_value` (`:128-142`) -- a 15-line awk helper that already strips
quotes and inline comments -- loses its `NR==1 && $0=="---"` fence guard and scans the whole
file for a column-0 key. The `"${phase:---}"` degrade-to-sentinel behavior stays (SP-11).
`canonical/aid/scripts/housekeep/cleanup-classify.sh`: the three signal reads (`:326`, `:458`,
`:538`) retarget the filename and their `fail:no STATE.md found` diagnostics.

**One honest caveat, carried not fixed.** `cleanup-classify.sh`'s signals read
`> **Status:** Deployed` and a `## Deploy Status` section -- neither of which exists in the
current template (which has `## Deploy State` and a `> **State:**` blockquote). Those signals
are therefore **already** returning their `fail:` reason against a current-shape work. This
refactor preserves that outcome (the signal still degrades to `fail:` with a reason, and
`scan_s6` still offers every folder with the signals as informational context only) and does
**not** repair it: repairing it would change observable behavior, which `restructure` forbids
(`REQUIREMENTS.md §4 Out of Scope`). Recorded in `§L-12` as a finding to route onward, not a
silent pass.

No new shared accessor script is introduced. `coding-standards.md § Configuration Access`
mandates reading `.aid/settings.yml` only via `read-setting.sh` and never hand-parsing it, and
the analogous rule for state would be a `read-state.sh`. **The grounds may not rest on the reader
count.** There are three shell readers, not two (`§L-10` names the third), so a count-based
trigger -- "if a third shell consumer ever appears, that is the moment to extract it" -- is
already met and cannot carry the decision. The grounds that survive the third reader:

1. **A scalar accessor would serve two of the three, not three.** `enumerate-works.sh`
   (`_frontmatter_value`, `:128-142`) and `delete-pipeline.sh` (`:164-168`, the same helper --
   its body runs to `:178`) look up a column-0
   frontmatter scalar, and they are already *one* implementation: the latter's header states its
   helper is a "Verbatim mirror of `enumerate-works.sh` so a lifecycle/updated read here can
   never diverge from the skill-facing helper's own reading of the SAME frontmatter shape".
   `cleanup-classify.sh` reads nothing of that kind -- its three sites probe markdown
   *structure*: a `## Deploy Status` table walk (`:326`, `:458`) and
   `grep -m1 '^> \*\*Status:\*\*'` (`:538`) -- so it could not call a scalar accessor even if one
   existed, and after the conversion its signals still degrade to `fail:` exactly as they do
   today (the caveat above). Duplication of the scalar lookup is therefore two call sites
   governed by a stated mirror invariant, not three unrelated hand-rollings.
2. **The third reader is the one that cannot take the dependency.** `delete-pipeline.sh` lives
   under `dashboard/scripts/` with no `canonical/` source, no profile render and no PowerShell
   twin (`§L-10`). Sourcing a `canonical/aid/scripts/...` helper from it would introduce a
   `dashboard/` -> `canonical/` runtime coupling no other file in that directory has, and would
   make a *destructive-operation guard* resolve its reader through a second file at run time --
   a file whose absence or relocation makes the guard fail open, which is precisely the failure
   mode `§L-10` exists to close. A fifteen-line inline helper cannot be missing at run time.
3. **The cost is not "one script".** It is a Bash script plus its PowerShell twin plus its test
   suite plus a render fan-out across five profile trees and two dogfood trees (FR-12) -- to
   remove a fifteen-line duplication between two call sites whose non-divergence is already a
   documented invariant in the mirror's own header. (No test asserts that byte-identity today;
   `task-006` preserves it by making the fence-guard edit identically in both copies inside one
   task, which is the enforcement available without adding the script.)

**The extraction trigger, restated so it discriminates.** Not "a third shell consumer" -- that is
a count, and it is met -- but a *capability*: the first shell consumer that needs more than a
column-0 scalar (a nested key, a sequence entry, or the `§D-3` reject-list warnings) is the one
the 15-line scanner genuinely cannot serve, and at that point extraction is the right answer
(a YAML library is not, for these callers: C-3). Until then the mirror pair stays a mirror pair,
and the obligation that follows is stated in `§L-10`: removing the `NR==1 && $0=="---"` fence
guard is the **identical** edit in both copies, made inside one task (`task-006`) rather than
across two, because divergence between the mirrors is the only way this arrangement can fail.

#### L-6. Migration: the CLI format-stamp engine, not a standalone script

**Decision: a versioned hard cutover through the existing per-repo format migration.** No
dual-read compatibility window, and no new standalone converter invoked by hand.

The repo already has exactly the right machine, and REQUIREMENTS did not name it: `bin/aid`
carries `readonly AID_SUPPORTED_FORMAT=3` (`:116`) as the ".aid/ layout version ... bumped ONLY
on a breaking layout change"; `_aid_format_gate` (`:1987`) does a three-way classify
(repo newer -> refuse with a named error; repo older -> `WARN: ... Run: aid update`, suppressible
with `AID_NO_MIGRATE=1`; equal -> silent); and `_aid_migrate_repo` (`:2017+`) runs ordered,
WARN-not-fail steps and always returns 0. It is already wired to `aid update`, to the hidden
`aid __migrate-repo`, to the npm postinstall opt-in, and to a PowerShell twin, and it is
already covered by `tests/canonical/test-aid-migrate.sh`,
`test-aid-migrate-trigger.sh` and `test-release-migrate-smoke.sh`.

Therefore:

1. **Bump the format stamp to 4**, in all four carriers together (they are a documented
   lockstep set): `bin/aid:116`, `bin/aid.ps1:157` (`AidSupportedFormat`),
   `lib/AidInstallCore.psm1:79` (`$script:_AidSupportedFormat`), and the
   `${AID_SUPPORTED_FORMAT:-3}` fallback in `lib/aid-install-core.sh:2124`. Add the format-4
   note to the same comment block that documents formats 2 and 3. Two further hardcoded
   `${AID_SUPPORTED_FORMAT:-3}` fallbacks in `bin/aid` go with them: `:2727`
   (`_aid_scaffold_bare_project`, which writes `format_version` into a fresh `settings.yml`) and
   `:2813` (`aid projects add`'s newer-format refusal). Both are unreachable in production -- the
   `readonly` at `:116` wins -- but they exist for the extracted-function unit harnesses, which
   would otherwise compare a repo stamped 4 against a supported 3. The PowerShell side has no
   equivalent (every `bin/aid.ps1` and `lib/AidInstallCore.psm1` site reads the constant), so this
   addition is bash-only and complete at those two sites.
2. **Add a conversion step to `_aid_migrate_repo`** and to its PowerShell twin: for every
   `.aid/works/*/STATE.md` (and, on the full layout, every `deliveries/*/STATE.md` and
   `deliveries/*/tasks/*/STATE.md`), emit `STATE.yml` preserving every scalar, every table row
   and every Q&A entry, verify the result parses and round-trips, then delete the `.md`. WARN-not-
   fail per the engine's contract; **idempotent** (a work with a `STATE.yml` and no `STATE.md` is
   a no-op); and **fail-closed per file** on a non-placeholder DERIVED row (SP-3).

   **"WARN-not-fail" and "the converter exits non-zero" are separate levels, and MUST NOT be
   asserted of the same one.** They cannot both
   describe the CLI's exit status, and the engine's contract wins: `_aid_migrate_repo` documents
   that "Each step is WARN-not-fail: a step failure logs WARN and the next step runs; the function
   always returns 0 (SEC-4 / NFR12)" (`bin/aid:2012-2013`), and changing that is a shipped-CLI
   behavior change outside this `restructure`. So the data-loss guard is scoped to the **file**,
   not to the run:
   - The converter *helper* returns non-zero and names the file and the section. That is the
     "exits non-zero" a test asserts -- at the helper's own level, which is where it is meaningful.
   - The offending file is **not converted**: no `STATE.yml` is written and the `STATE.md` stays in
     place. Nothing is dropped, which is the property SP-3 exists to guarantee.
   - The step logs `WARN:` naming the file, the section and the remedy (run
     `migrate-work-hierarchy` first), then `_aid_migrate_repo` continues and returns 0.
   - The repo format stamp **still advances**, and that is safe rather than a loophole: the stamp is
     written by the engine's STEP 1 settings repair/synthesis
     (`_aid_migrate_repair_settings_era_a` / `_aid_migrate_synthesize_settings_era_b`), which runs
     before every later step, so no later step can gate it without reordering the engine. The
     unconverted work is still diagnosed, not silently lost: the readers' legacy detector emits a
     `parse_warning` naming the migration command (SP-9), and re-running `aid update` after the
     hierarchy migration converts it, because the step is idempotent.

   One consequence to state plainly for SP-12: "a second run changes nothing" holds for a **fully
   converted** work. A second run after a refused file's DERIVED row has been resolved *does*
   convert that file -- the intended remedy path, not an idempotency violation.
3. **NFR-8 falls out for free**, which is the strongest argument for this mechanism: an adopter
   running an older CLI against a converted repo already gets the format gate's "newer than this
   CLI supports" refusal, and an adopter with a stale repo already gets
   `WARN: ... Run: aid update`. No new diagnostic surface is invented.

**Why hard cutover, not dual-read.** Both twins enumerate *every* work across *every* worktree
root (`enumerate-works.sh`; `reader.mjs _enumerateWorktreeRoots:3364`), so a half-converted repo
renders a half-broken dashboard; and keeping both parsers alive forever forfeits the entire
rationale (`REQUIREMENTS.md §2`) -- the whole point is deleting markdown grammars, not owning two
of them. The readers keep exactly one line of legacy awareness: *a `STATE.md` with no sibling
`STATE.yml` is diagnosed, not parsed* (SP-9).

**Alternatives rejected.** (a) *A standalone one-shot script*, on the
`migrate-work-hierarchy.{sh,ps1}` precedent REQUIREMENTS named: rejected because it has no
automated caller -- verified, that script is referenced by nothing in `canonical/`, `bin/`, `lib/`
or `packages/`; its only callers are its own test suite and the ASCII-only allowlist. It therefore
runs only when someone runs it by hand, which is exactly the "reader support shipped,
adopters stranded" failure C-6 warns about. (b) *An indefinite dual-read window*:
rejected as above. (c) *Converting on first write*: rejected -- it makes the read path
non-deterministic and leaves the dashboard half-broken until every work happens to be written.

**`migrate-work-hierarchy.{sh,ps1}` stays markdown-in, markdown-out, and is a scope reduction
against REQUIREMENTS.** It is an *era* migration: its input is by definition a legacy monolithic
markdown `STATE.md` and its output feeds the format-4 converter as the next step. Ordering rule,
documented in its header and in the KB: **hierarchy migration first, format conversion second.**
Consequence: `tests/canonical/test-migrate-hierarchy.sh` (89 `STATE.md` references) and the
fixture tree `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/` are
**out of** the FR-13 change-set. REQUIREMENTS FR-13 listed them as the heaviest in-scope items,
but explicitly framed its list as a "candidate inventory ... to be triaged in-scope vs.
out-of-scope before editing" -- this is that triage, and it removes the single largest test
edit in the work while *increasing* AC-1 confidence, because those 89 assertions stay untouched
and keep proving the era migration still works.

**Live works during the conversion (C-6, SP-18).** Works are live right now across multiple
worktrees, including this work's own state file. Sequencing rule: readers and CLI accept
`STATE.yml` (L-3, L-4, L-5, and the format gate) **before** any live work is converted; the
conversion of the repo's own works is a single step that leaves no work in the old format; and
this work's own tracking is written in whichever format is live at that moment. A tree still
holding markdown state files after the cutover is not silently broken -- it is diagnosed by the
format gate and by the reader warning, and repaired by `aid update`.

#### L-7. Skills, templates and prose (FR-8)

Mechanical but wide. Every recipe that names the path, copies a template, or describes a
section: `shortcut-engine.md` (`§ INTAKE Step 4`'s `cp work-state-template`, every
`writeback-state.sh --pipeline` block, and each `## Lifecycle History` append instruction, which
becomes "append an entry to the `lifecycle_history` sequence"); `aid-execute`
(SKILL.md + `state-execute.md`, `state-review.md`, `state-delivery-gate.md`, `state-fix.md`);
`aid-plan`, `aid-specify`, `aid-describe`, `aid-define`, `aid-detail`, `aid-deploy`,
`aid-triage`, `aid-housekeep`, `aid-review`, `aid-ask`, `aid-monitor`. The mandatory
state-write protocol text is preserved verbatim in meaning -- only the target notation changes.
Agent-context files (`CLAUDE.md`, `AGENTS.md`) likewise, wherever `STATE.md` is named by path;
per `CLAUDE.md`, no KB doc may name this work or its folder (C-7, SP-15).

**Templates that *resolve and read* a work state file, not just mention one.** The skill list above
is not the whole prose surface, and the distinction matters because these are routing logic written
as prose: they decide what runs next from a value they read out of the file.
`grep -rl STATE.md canonical/aid/templates` returns **30 files**; the ones that resolve a work-tree
state file are, at minimum:

- `work-initiation-gate.md` -- "The gate allocates **nothing**. It reads the chosen work's
  `STATE.md` frontmatter (`pipeline.path`, `phase`, `lifecycle`, and -- for flattened works --
  `delivery_state`)" (`:131`) and then routes the user to a resume door off those values, including
  a row that dispatches on `STATE.md` `phase` directly (`:141`). Left unretargeted, the CONTINUATION
  path resolves a path that no longer exists and the gate cannot route at all.
- `work-initiation-gate.md:123` -- the same doc's NEW-work branch *scaffolds* `STATE.md` from the
  template, so it binds to `§L-1`'s filename as well as reading one.
- `downstream-worktree-entry.md:119` -- names "a `STATE.md` read" as one of the first local
  `.aid/works/{work}/…` resolutions that must land *inside* the entered worktree.
- `subagent-heartbeat-protocol.md:151` -- the cooperative stop-poll re-reads "the work `lifecycle`
  from `STATE.md` frontmatter" and halts on a non-`Running` value.
- `shortcut-engine.md`, already named above (`§ INTAKE Step 4`'s `cp` of the template, every
  `writeback-state.sh --pipeline` block, each `## Lifecycle History` append), plus the three state
  templates themselves (`§L-1`).

A second, distinct group *writes* to a work state file or names a section FR-2b retires, and is in
scope for the same reason: `dispatch-protocol-checklist.md:34` and `long-wait-protocol.md:80` (both
"add a row to `STATE.md ## Calibration Log`"), `delivery-issues.md:11`, `:34`, `:42`
(`STATE.md ## Quick Check Findings`, `## Delivery Gates`), and
`connectors/consumption-protocol.md:84-87`, `:135` (the `ticket_ref` resolution table, which names
the work/delivery/task `STATE.md` frontmatter at each level).

Not every one of the 30 converts. `discovery-state-template.md` and every reference to
`.aid/knowledge/STATE.md` must **not** change (the out-of-scope ledger) -- that covers most of the
`kb-authoring/` and `knowledge-summary/` matches, which are ledger or KB-doc references and are
triaged per file rather than converted wholesale; and `rough-time-hints.md:55` is a historical
mention, not a resolution. This enumeration is a completeness aid, not the enforcement: SP-15's
sweep already spans *every* template and `task-014`'s title is universal, so nothing here changes
what is asserted -- it changes what an executor will remember to look at.

#### L-8. The review-exclusion mechanism (FR-10) -- minimal, and where it lives

Three edits, one test, no new gate. Modeled on the KB precedent REQUIREMENTS identified:
`list_reviewable` lives as a shell function *inside* the reference doc
`aid-discover/references/doc-set-resolve.md`, and `tests/canonical/test-kb-review-surface.sh`
extracts that function from the doc and asserts its behavior (RS03 proves the meta ledgers are
excluded, and the test comments say it exists "so this test guards against drift between the doc
and the asserted behavior"). Same shape here:

1. **`canonical/aid/templates/reviewer-dispatch.md § ARTIFACTS UNDER REVIEW`** -- in the single
   upstream doc every brief derives from -- gains the rule: *a state file is never listed in
   `{{ARTIFACTS}}`; state churn appearing in a reviewed diff is not a finding and is not an OOS
   row either (it is not an observation about an artifact)*. That doc's `## Brief generation`
   (`:200`) already mandates deriving the list from a deterministic source
   ("`git diff --name-only <base>..HEAD`"), so the rule lands with a one-line filter beside it,
   rule and filter defined once in this section, which the dispatcher applies at that derivation
   point. That is the whole mechanism: one rule, one filter, one
   home.
2. **`canonical/skills/aid-execute/references/reviewer-brief.md`** -- line 66 stops naming "every
   task's `STATE.md` row" in the per-delivery `{{ARTIFACTS}}`, and the per-task `DELIVERABLES`
   output location (line 54) is restated so it no longer implies the state file is reviewed
   content. Two notes while editing it: the reviewer still *writes* its outcome into state
   (A-3), and line 54's current target `STATE.md ## Tasks State` names a **DERIVED** section,
   which is wrong today independent of this refactor -- the correct target is the
   `tasks_lifecycle` entry on the flat path, or the per-task file on the full path. Fixing that
   pointer is in scope precisely because the line is being rewritten anyway.
3. **`shortcut-engine.md § GATE`** -- both passes already exclude state files by listing only
   REQUIREMENTS/SPEC/PLAN/BLUEPRINT (Pass 1) and the `DETAIL.md` set (Pass 2); each pass's
   `OUT OF SCOPE` bullet (`:720`, `:751`) states the exclusion explicitly so it cannot regress.
4. **Test**, in the RS03 shape: extract the filter from `reviewer-dispatch.md`, assert it drops
   every state-file path shape (all three levels, both layouts, `.md` legacy and `.yml`) and
   keeps every authored-artifact path; plus a static assertion that no brief template names a
   state file inside an `ARTIFACTS` block (SP-13).

**Not added, deliberately:** no new ledger column, no new severity, no new grade mechanism, no
change to `grade.sh` (FR-10d). `grade.sh` grades a ledger and reads no state file; SP-13's
grade-equality clause is what proves the exclusion needed no grading change.

#### L-9. Tests: the oracles (FR-13, and decision 7)

Two acceptance properties need two different oracles, and they are not interchangeable.

**Behavior preservation (AC-1 / SP-16) -- oracle: the existing suites, run twice, compared per
test.** Procedure, concretely: on the pre-refactor tree run `HOME="$(mktemp -d)" bash
tests/run-all.sh` and `python -m pytest dashboard/reader/tests dashboard/server/tests`
(`test-landscape.md § Test Commands`), and record each suite's own summary line -- never a grep
over stdout, which undercounts on a hang or timeout. Repeat post-refactor and diff the per-test
pass/fail sets. The permitted difference is exactly the enumerated change-set; any other newly
failing test *and any newly passing one* is a regression. In-scope suites, from the real
directory rather than invention: `tests/canonical/test-writeback-state.sh` (the writer's own
unit harness, Units 1-21, including Unit 8/17 concurrency, Unit 12 isolation, and Unit 14's
`|` rejection -- which **inverts** under FR-4b and is therefore a change-set entry, not a
regression),
`test-disjoint-merge.sh`, `test-delivery-gate-aggregate.sh`, `test-task-state-transitions.sh`,
`test-work-state-template.sh` (the template-shape suite -- broken down separately below, because it
is the heaviest entry here),
`test-pipeline-status-walkthrough.sh`, `test-delete-pipeline.sh` (the oracle for the
`§L-10` `Running`-guard property, AC-13a),
`test-shortcut-engine-contract.sh`, `test-housekeep-workfolder-safety.sh`,
`test-aid-migrate.sh`, `test-aid-migrate-trigger.sh`, `test-release-migrate-smoke.sh`,
`test-aid-cli-parity.sh` (the format-stamp twin), the four further template-referencing suites
listed below, plus the reader suites
`test_work003_state_schema.py`, `test_work001_delivery_layouts.py`,
`test_flattened_layout_parity.py`, `test_task014_fixtures.py`, `test_integration.py`,
`test_reader.py`, `test_derivation.py`, and the server suite
`test_write_enabled_cross_runtime_parity.py` (the oracle for the `§L-11` write-path property,
AC-13b). Explicitly **not** to be edited (editing one is itself a
scope defect): `test-discover-preflight.sh`, `test-summarize-preflight.sh`,
`test-kb-freshness-check.sh`, `test-grade-summary.sh`, `test-kb-review-surface.sh` -- these
reference only the out-of-scope discovery-area ledger. `tests/coverage-baseline.tsv` is
**re-bootstrapped**, not row-edited, because this is a corpus-wide change (its 87 `STATE.md`
references are a symptom of that, not a work item).

**`test-work-state-template.sh`, stated at full extent** -- because AC-1/SP-16 uses this
enumeration to tell an intended format-asserting update from a regression, an understated version
of it silently defeats the oracle. Its index runs **WS01-WS20**, of which **16 are live** (WS06,
WS11, WS17 and WS18 were removed as comment-text assertions). Two structural facts set the scope.
First, **most** assertions in the file resolve their subject through
`WORK_STATE` / `DELIVERY_STATE` / `TASK_STATE` (`:55-57`), each pinned to a
`canonical/aid/templates/*-state-template.md` path that FR-3 renames -- so the whole suite is a
change-set entry at the path level, not a subset of it; the exceptions resolve
`DOGFOOD_WORK_STATE` (`:61`) or `FIRST_RUN` (`:62`), plus WS08, which resolves its subject inline
via `find "$REPO_ROOT/profiles"` (`:167`) -- the `PROFILES_DIR` assignment (`:63`) is dead and
resolves nothing. Second, the
assertions the conversion breaks *on content* number **eight**, not two:

| Assertion | What breaks |
|---|---|
| WS01 (`:66-71`) | asserts the `## Pipeline State` heading, which `§D-4` retires |
| WS02 (`:81-86`) | four bold-line field checks (`**Phase:**`, `**Updated:**`, `**Block Reason:**`, `**Block Artifact:**`); its three frontmatter-key checks (`:88-93`) survive |
| WS05 (`:126-129`) | asserts the whole `active_skill:` line, with the `aid-{skill}` / `none` enum hint standing as the key's own value; `§D-4` / SP-20(a) move that hint into a full-line comment above the key |
| WS08 | the same `## Pipeline State` heading in every rendered profile tree |
| WS12, WS13, WS15, WS16 | markdown headings in `delivery-state-template` / `task-state-template` -- `## Cross-phase Q&A`, `## Tasks State`, `## Quick Check Findings`, `## Dispatch Log` -- both files converted by FR-3 |

Each is retargeted to the `.yml` shape and recorded as an intended change-set entry; none is a
regression. WS03/WS04/WS10/WS14 survive in substance (enum members and mutable-cell keys,
which `§D-2` preserves byte-for-byte) but move to the renamed file, as does WS05's *first*
assertion (`:122-125`, the bare `aid-{skill}` substring, which survives inside that full-line
comment); WS07 (`:61`) changes only the
dogfood path it resolves; WS09's two negative `Status` greps (`:185-199`) still pass against a
heading-less `.yml`, and two of the five templates it iterates are never converted; WS19/WS20
assert `aid-describe`'s seed prose and change only where it names the retired markdown fields.

**Four further template-referencing suites, same class.** Found by `grep -rl` for the three
template names under `tests/`, and in scope for `task-015`:

- `test-connector-consumption-linkage.sh` -- CL08c-e assert `ticket_ref` in all three
  `*-state-template.md` files; paths at `:60-62`.
- `test-ticket-retirement-structural.sh` -- T087-T089, the same three paths, at `:93-95`.
- `test-cutover-no-dangling.sh` -- CND12a-b resolve `work-state-template.md` and assert the absence
  of two `##` headings (`:124-130`).
- `test-describe-full-only.sh` -- `:233` onward builds a markdown work-state fixture carrying
  `## Pipeline State` / `## Interview State`, the shape FR-2b retires.

Omitting any of these four understates the change-set: a genuinely
regressed assertion in an unlisted suite is indistinguishable from an intentionally updated one,
which is precisely the discrimination SP-16 exists to make.

**Cross-format characterization (AC-2 / SP-8) -- oracle: a golden master recorded *before* the
refactor, not a live four-way comparison.** A live "legacy read vs converted read" comparison MUST
NOT be specified: it is
unsatisfiable by construction, because `§L-3`/`§L-4` delete the markdown state parsers and
`§L-6`/SP-9 specify that a legacy `STATE.md` is *diagnosed, not parsed*. A `_minimal_work_model`
cannot carry per-task state, lifecycle-history rows, Q&A entries or derived counts, so no
post-refactor read of a legacy tree can be field-equal to anything -- and the post-refactor legacy
read is *required* to warn, so a `parse_warning`-free legacy read is not an available
property. The oracle therefore has three legs, and **which build reads which tree
is part of the specification**:

- **(a) Record the baseline, on the pre-refactor tree.** The legacy-markdown fixture work tree is
  read by the **pre-refactor** `reader.py` and `reader.mjs`; the two payloads must be equal on
  every rendered field and neither may raise a `parse_warning`. That payload is committed as the
  golden baseline. It is a committed test fixture, not a work-folder artifact -- no work folder's
  contents are an input to it, because a work folder is transient and no permanent artifact may
  depend on one (`CLAUDE.md § Tracking discipline`). Because leg (a) needs the **pre-refactor** parser
  code, and `task-011` runs after `task-003`/`task-004` have already replaced it, the capture is
  performed by running both readers as of the pre-refactor revision in a scratch checkout
  (`git worktree add` / `git show` into a temp dir) and committing the resulting payload. That use
  of git history is a one-time authoring step inside `task-011`, **not** something the suite does
  at run time: the suite reads the committed payload file only, because CI clones shallowly and a
  test that resolves repo history there fails.
- **(b) Compare the conversion, on the post-refactor tree.** The same fixture tree after the
  `§L-6` conversion is read by the **post-refactor** `reader.py` and `reader.mjs`; both payloads
  must equal the committed golden baseline on every rendered field (lifecycle, phase, active
  skill, updated, delivery state, gate tier/grade/timestamp, per-task
  state/review/elapsed/notes/display-name, lifecycle-history rows, Q&A entries, derived counts and
  percentages), and neither may raise a `parse_warning`.
- **(c) Assert the legacy read degrades, identically in both runtimes.** The *unconverted* legacy
  tree read by the **post-refactor** readers must return the minimal-model degradation with the
  same `parse_warning` naming the file and the migration command. This leg asserts a required
  behavior (SP-9, AC-5); it is not a shortfall of (b), and its warning set is asserted explicitly
  rather than tolerated.

Home: the existing cross-runtime parity suite family, whose `test_flattened_layout_parity.py`
already builds a flat-layout fixture and asserts `reader.py` and `reader.mjs` read it
identically -- extend that shape, reusing its fixture builder and its `subprocess` Node
invocation. Both layouts are covered (flat here, full via `test_task014_fixtures.py`'s
hierarchical fixture). The L-4 conformance corpus is a separate, complementary oracle rather than
a leg of this one: one input per permitted shape, per rejected construct, per quoting mode, per
implicit-typing literal, run identically by both twins (SP-1, `task-005`).

**Gates that must stay green regardless (SP-14):** `test-dogfood-byte-identity.sh` (resync
`.claude/` from `profiles/claude-code/` after the generator runs -- skipping this is the
classic red-CI mistake), `test-multitool-isolation.sh` T21-T26 (no foreign-tool root path in an
operational script, comments included), the render-drift check (run the **full**
`run_generator.py`, not a per-script renderer, or drift fails on stale emission manifests), and
`check-version-sync.sh`. Per `test-landscape.md`, several heavy gates are master-only and the
coverage-parity gate enforces as soon as its baseline file is present -- so the re-bootstrap is
part of the change, not a follow-up.

#### L-10. The delete-pipeline safety guard: `dashboard/scripts/delete-pipeline.sh` (FR-7a)

Belongs logically beside `§L-5` -- it is the **third** shell state reader, and the only one whose
read gates a destructive operation.

| Today | Target |
|---|---|
| `LIFECYCLE="$(_frontmatter_value "$CANDIDATE/STATE.md" lifecycle)"` (`:348`), then `[[ "$LIFECYCLE" == "Running" ]] && exit 7` (`:349`) | Same guard, reading `$CANDIDATE/STATE.yml` |
| `_frontmatter_value` (`:164-168`) -- a documented "verbatim mirror of `enumerate-works.sh`" whose awk opens with `NR==1 && $0=="---" { infm=1; next }` and exits at the closing `---` | The fence guard is removed and the scan covers the whole document -- **the identical change `enumerate-works.sh` gets in `§L-5`**, and it must stay a verbatim mirror, because that is the property that keeps the two from diverging on the same file |

**Why this is a safety defect and not a cosmetic miss.** `_frontmatter_value` returns empty for a
missing file (`[[ -f "$file" ]] || return 0`, `:166`), and the guard fires only on the exact
string `Running`. So retargeting neither half, or only one half, yields an empty `LIFECYCLE` for
**every** work -- the guard becomes an unconditional no-op and the script will delete a running
pipeline's work folder or worktree. The two halves are one atomic change. The gate is behavioral,
not textual (AC-13a / SP-19): against a converted work with `lifecycle: Running` the script must
still exit 7. `tests/canonical/test-delete-pipeline.sh` is the oracle, and it is already in the
`§L-9` in-scope suite list.

Only one copy exists -- no `canonical/` source, no profile render, no PowerShell twin (verified:
`delete-pipeline.sh` occurs exactly once in the tree). So it is hand-edited, like the
`dashboard/scripts/writeback-state.sh` fork, and no render step covers it.

The guard's *pre-existing* fail-open on a genuinely **missing** state file is unchanged and
carried to `§L-12`, not repaired: repairing it is an observable behavior change `restructure`
forbids -- the same disposition `§L-5` gives `cleanup-classify.sh`'s stale signals.

**Task-set consequence, and where it landed.** `task-006` is now
"Retarget the **three** shell state readers to STATE.yml" (`BLUEPRINT.md § Tasks`) and owns
`delete-pipeline.sh` -- both the path read and the `_frontmatter_value` fence guard -- as one
atomic change, alongside the identical fence-guard edit to `enumerate-works.sh`, so the mirror
pair cannot diverge across tasks. `task-015` (in-scope canonical shell suites) carries
`test-delete-pipeline.sh` and asserts the AC-13a / SP-19a guard property behaviorally.

#### L-11. The dashboard server layer: `server.mjs` / `server.py` / `home.html` (FR-4e)

Belongs logically beside `§L-4` -- it is the write-path **caller** of `§L-2`, in two runtimes.

| Today | Target |
|---|---|
| `dashboard/server/server.mjs:1242`, `:1280`, `:1555` -- each `const env = { AID_STATE_FILE: join(workDir, "STATE.md"), AID_WORK_DIR: workDir }` before spawning `writeback-state.sh` (task set-notes, pipeline `Lifecycle=Completed`, task rename) | `join(workDir, "STATE.yml")` at all three |
| `dashboard/server/server.py:1503`, `:1540`, `:1803` -- the same three, `{"AID_STATE_FILE": str(work_dir / "STATE.md"), ...}` | `str(work_dir / "STATE.yml")` at all three, edited in the same change as the Node three (C-4 parity) |
| `dashboard/home.html:5816` -- the raw-state viewer's **fallback** source label, `('.aid/works/' + workId + '/STATE.md')`, used when the reader supplied no `rawState.path`; plus ten sibling `STATE.md` UI strings and comments (`:3229`, `:4970`, `:5574`, `:5791`, `:5800`, `:5808`, `:5828`, `:5860`, `:5865`, `:5957`) | Retargeted with them, so the UI never labels a `STATE.yml` as `STATE.md` |

**Failure mode if missed.** `AID_STATE_FILE` is an explicit override, so it wins over the writer's
own layout auto-detection: an unretargeted value points at a path that no longer exists and the
writer dies `"$STATE_FILE does not exist"` with exit 1 (`writeback-state.sh:1414`, and the parallel
existence checks at `:805`, `:894`, `:1039`, `:1133`, `:1206`, `:1240`). Every write-enabled
dashboard edit surface breaks at once, in both runtimes, with no reader-side symptom to hint at
the cause. `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` is the existing
oracle and is now listed in `§L-9`.

Note the asymmetry that hid this layer: `reader.mjs` was fully enumerated in `§L-4` because it is
a *reader*; `server.mjs` / `server.py` touch state only as the writer's caller, and `home.html`
only as a label. None of the three parses state, so none appeared in the reader inventory -- which
is exactly why `§SP-15`'s verification search is rescoped to cover `dashboard/` rather than only
docs and renders.

**Task-set consequence, and where it landed.** `task-007` ("Collapse writeback-state.sh onto one
YAML single-key write path") owns the writer but not its callers, and `task-004` owns `reader.mjs`
but not `server.mjs`, so the six `AID_STATE_FILE` sites plus `home.html` needed an owner of their
own. That owner is **`task-020`** -- "Retarget the dashboard server write path and raw-state labels
to STATE.yml" (`BLUEPRINT.md § Tasks`; `Depends on: task-007`, because these sites are strictly
downstream of the writer they call). It was split out of `task-007` rather than folded into it:
a different language pair, a different runtime pair, a different failure mode and a different gate
(SP-19b, not SP-4/5/6). Both runtimes stay inside `task-020`
because `server.mjs` and `server.py` are a lockstep twin pair under C-4. `task-016` (in-scope
dashboard reader/server suites) carries `test_write_enabled_cross_runtime_parity.py` and takes
`task-020` as a dependency, since that suite is this layer's only oracle.

#### L-12. Open items, and what is carried forward

- **NFR-10 (performance budget) -- still open, deliberately.** No measured baseline for reader
  parse time exists and no target was captured. The refactor is not motivated by performance
  (`refactor-kind: restructure`), so no number is invented here. What *is* asserted is the
  structural cost property: one file read per work, no added stat or glob (SP-10). If a
  measurement is wanted, it is a separate `performance`-kind work with its own captured
  baseline.
- **`cleanup-classify.sh` signal staleness (found here, carried, not fixed).** Its signal (ii)
  and status-note read `> **Status:**` and `## Deploy Status`, which the current template does
  not emit (`§L-5`). Behavior is preserved as-is; the finding is routed onward rather than
  silently carried, because fixing it would be a behavior change this refactor forbids.
- **`delete-pipeline.sh`'s fail-open on a missing state file (same class as the above).** Its
  `_frontmatter_value` returns empty for an absent file (`:166`) and the `Running` guard fires only
  on the exact string, so a work folder with no state file has always been deletable. Unchanged by
  this work -- `§L-10` retargets the path and the fence guard so the guard keeps firing for a
  `Running` work, and nothing more; hardening the missing-file case would be an observable behavior
  change this `restructure` forbids. Routed onward, not silently carried.
- **Detail-view findings/gate parsers (same class).** `parse_quick_check_findings` and
  `parse_delivery_gate` scan the work-level file for sections the current template does not
  emit (`§D-4`). Retargeted, still empty, staleness preserved and recorded.
- **`display_name` undeclared in the task template.** Written by the writer today
  (`writeback-state.sh:829`), absent from `task-state-template.md`'s frontmatter. Declared in
  the new template as a documentation fix; must be recorded as such in the SP-2 comparison so it
  is not mistaken for an added key.
- **A-5 (no JSON Schema, no CI schema gate)** -- carried unchanged. The enum validation in
  `writeback-state.sh` plus the L-4 conformance corpus remain the only machine checks. Revisit
  only if a defect shows enum validation is insufficient.
- **A-1 (the exact filename string)** -- settled here as a design decision on repo evidence
  (`§D-1`), and cheap to confirm at APPROVAL because it lives in one constant per consumer.
- **A-2, A-3, A-4, A-6** -- all settled above: A-2 in `§D-2` (lift verbatim, asserted by SP-2),
  A-3 in `§L-8` (artifact review and grading only -- state stays written, committed, read and
  authoritative), A-4 in `§D-2` (true for every current-shape work, enforced by the converter's
  per-file refusal), A-6 in `§D-5` (the subset expresses every value in play, including newline-bearing
  ones).
