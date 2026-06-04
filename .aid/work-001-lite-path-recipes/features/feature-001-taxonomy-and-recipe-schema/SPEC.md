# Taxonomy & Recipe Schema

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-03 | Feature identified from REQUIREMENTS.md §§4,5,7,9 | /aid-interview |

## Source

- REQUIREMENTS.md §1 Objective, §4 Scope, §5 Functional Requirements, §7 Constraints,
  §9 Acceptance Criteria (AC1, AC3, AC7)
- design-notes.md (taxonomy + schema decisions)

## Description

Establish the foundation for the lite-path redesign: a single, clean-break rename of the
lite work-type / recipe `applies-to` enum from four values to three —
`{bug-fix, new-feature, refactor}` (plus `*` for cross-type) — applied across **all**
canonical sources (the recipe files, the `aid-interview` state machine, and the work-state
template). The real old enum is `{bug-fix, small-refactor, single-doc, small-new-feature}`;
`bug-fix` keeps its value, `small-refactor`→`refactor`, `small-new-feature`→`new-feature`,
and `single-doc` is eliminated (docs & reports fold into add/change).
A new agent-read `summary:` one-line front-matter convention is added to the recipe schema
so the description-first TRIAGE (feature-002) can match a free-form description to a recipe.

**No `parse-recipe.sh` logic change is required** — the validator already tolerates unknown
front-matter fields and does not enum-check `applies-to`; the only script-area touch is
updating the test fixtures that hard-code old enum values so the smoke test stays green.

## User Stories

- As an **AID maintainer**, I want one consistent 3-value work-type enum across all canonical
  files so that the taxonomy is unambiguous and greppable.
- As the **interviewer agent**, I want each recipe to carry a `summary:` line so I can match a
  user's work description to the right recipe.

## Priority

Must

## Acceptance Criteria

- [ ] (AC1) Work-types renamed/collapsed to `{bug-fix, new-feature, refactor}` across the
  files feature-001 owns (see § Scope & Files to Change) — no `small-refactor` /
  `small-new-feature` / `single-doc` references remain **as enum/workType tokens** in any
  feature-001-owned file. **Work-level scope note:** the repo-wide "zero old enum tokens across
  **all** canonical files" sweep is a *work-level* gate verified only after the **last** feature
  (feature-003) lands — `state-triage.md` (feature-002) and the five recipe files (feature-003)
  still carry old tokens until their owning features complete, so feature-001 alone cannot and
  must not be faulted for the full-repo sweep. Verify feature-001 with a context-aware search
  (`applies-to:` front-matter, workType-mapping tables), NOT a bare substring grep — the latter
  false-positives on `canonical/templates/reviewer-ledger-schema.md` ("single-doc cosmetic
  issue", a severity-description phrase that must NOT be edited). Clean break: no
  alias/read-compat, no migration shim.
- [ ] (AC3) `summary:` field added to the recipe schema docs (`recipes/README.md`) and the
  recipe template; `applies-to` enum documented as `{bug-fix, new-feature, refactor, *}`.
  `parse-recipe.sh` continues to validate without logic changes (unknown-field tolerance
  confirmed).
- [ ] (AC7) `tests/canonical/test-parse-recipe.sh` stays green (fixtures at lines ~145/205
  embed `applies-to: small-new-feature` and must be updated to the new enum).
- [ ] (AC6, KB — enum scope) KB enum references updated to the 3-value taxonomy:
  `domain-glossary.md` (`workType` term enum on line 147 + the `LITE-REFACTOR`/`LITE-FEATURE`
  token text on lines 150–151), `schemas.md` (`Work Type` + `applies-to` enums), and
  `pipeline-contracts.md` (inline enum comment). (The `LITE-DOC` glossary row (line 149) is
  deferred to feature-002; recipe-catalog glossary update is owned by feature-003; TRIAGE-flow
  KB description by feature-002.)
- [ ] Canonical change re-rendered to all 5 install trees via `/aid-generate` (byte-identical).

---

## Technical Specification

> This is a documentation/markdown + bash-tooling change to `canonical/` (AID editing
> itself), not an application feature. The sections below are adapted accordingly: no Data
> Model / API layers, but **Scope & Files to Change**, **Enum Rename Map**, **`summary:`
> Schema Addition**, **Test-Fixture Updates**, **KB Updates**, and **Render & Verification**.
> Every claim is grounded against the files on disk as of this writing; line numbers will
> drift as edits land, so each row also names a grep-recoverable anchor.

### Overview

A single clean-break rename of the lite work-type / recipe `applies-to` enum from four
values to three: `bug-fix` (unchanged), `small-refactor`→`refactor`,
`small-new-feature`→`new-feature`, and `single-doc` **eliminated** (docs & reports fold
into add/change under new-feature / refactor). Plus a new agent-read `summary:` one-line
front-matter convention on the recipe schema. The change is entirely in `canonical/` source
+ KB + the canonical smoke test; it is then re-rendered to the 5 install trees via
`/aid-generate`. **No `parse-recipe.sh` logic change** (proven in § `summary:` Schema
Addition below).

**Clean partition across the three features** (the orchestrator owns all three and specs them
sequentially in one work/delivery):

- **feature-001 = the enum DEFINITION** — the schema (recipe README + template), the generic
  work-state-template enum line, the canonical test fixtures, and the KB enum references. This
  feature.
- **feature-002 = the CONSUMER** — the TRIAGE / interview state machine (`state-triage.md` and
  the sub-path interview bodies). feature-002 owns **all** of `state-triage.md`.
- **feature-003 = the recipe-file INSTANCES** — the recipe catalog: the five existing recipe
  **files** (`method-refactor.md`, `add-crud-endpoint.md`, `write-release-note.md`,
  `bug-fix.md`, `add-unit-test.md`) including both their `applies-to:` tokens and their
  filenames / `name:` fields and any re-target (e.g. `write-release-note`→`add-docs`/
  `add-report`).

feature-001's authoritative file list was produced by a context-aware search for the old enum
tokens (`small-refactor`, `small-new-feature`, `single-doc`) as enum/workType tokens, then
**filtered to only the DEFINITION-layer files** (consumer-layer `state-triage.md` and the
instance-layer recipe files are excluded — they belong to feature-002 / feature-003). The one
benign-prose false positive (`canonical/templates/reviewer-ledger-schema.md:82` "single-doc
cosmetic issue" — a `[LOW]` severity description) must **not** be edited.

### Scope & Files to Change

**Canonical source (recipe schema — the DEFINITION layer):**

| File | Lines / anchor | Change | Kind |
|------|----------------|--------|------|
| `canonical/recipes/README.md` | 28–34 (Seed Catalog table), 68–76 (valid `applies-to` values table), 241 (`applies-to: small-new-feature` in the multi-task example), 339 + 364–369 (T3→workType mapping prose + table) | Rename enum tokens per § Enum Rename Map; collapse the `single-doc` row out of the valid-values table; add the `summary:` field to the YAML front-matter field table + the example block (§ `summary:` Schema Addition). README is **schema/doc, not a recipe instance** — it is feature-001's, not feature-003's. | canonical |
| `canonical/templates/recipe-template.md` | 88–93 (the "Valid `applies-to` values (from feature-005 type-aware triage)" comment block) | Rename `small-refactor`→`refactor`, `small-new-feature`→`new-feature`; delete the `single-doc` line; add a `summary:` line to the front-matter example (line 1–6) + the fields table (81–86) | canonical |
| `canonical/templates/work-state-template.md` | **18 only** (`**Work Type:** bug-fix | single-doc | small-refactor | small-new-feature | …`) | Update the Work Type enum to `bug-fix | new-feature | refactor` (drop `single-doc`). **Line 19 (the `Sub-path` enum `LITE-BUG-FIX | LITE-DOC | …`) is NOT touched** — sub-path fate is feature-002. | canonical |

> **Recipe FILES are out of feature-001 scope.** The five existing recipe instances —
> `method-refactor.md`, `add-crud-endpoint.md`, `write-release-note.md`, `bug-fix.md`,
> `add-unit-test.md` — are owned **entirely by feature-003** (their `applies-to:` tokens, their
> filenames, their `name:` fields, and the `write-release-note`→`add-docs`/`add-report`
> re-target). feature-001 does **not** edit any recipe file. This eliminates the former OQ-2.
>
> **`state-triage.md` is out of feature-001 scope.** feature-002 owns **all** of it; its
> description-first rewrite replaces the T3 menu + workType→Sub-path tables wholesale and
> naturally emits only new-enum tokens. feature-001 does not edit it. This resolves the former
> OQ-1.

**Tests:**

| File | Lines / anchor | Change | Kind |
|------|----------------|--------|------|
| `tests/canonical/test-parse-recipe.sh` | 145 (`applies-to: small-new-feature` in the EXACT_RECIPE fixture), 205 (same in the MULTI_RECIPE fixture) | Change both to `applies-to: new-feature` so the canonical smoke test (reports "Tests passed: 113") stays green (AC7). See § Test-Fixture Updates. | test |

**KB (`.aid/knowledge/`):**

| File | Lines / anchor | Change | Kind |
|------|----------------|--------|------|
| `.aid/knowledge/schemas.md` | 180 (`Work Type` enum), 369 (`applies-to` enum row in §10 Recipe Front-Matter) | Update both enums to the 3-value taxonomy. | KB |
| `.aid/knowledge/domain-glossary.md` | 147 (`workType` term enum), 150 (`LITE-REFACTOR` term text), 151 (`LITE-FEATURE` term text) | Update the `workType` enum to `bug-fix | new-feature | refactor`; replace `small-refactor`→`refactor` and `small-new-feature`→`new-feature` in the LITE-REFACTOR / LITE-FEATURE term text. **Line 149 (the `LITE-DOC` row) is NOT touched — deferred to feature-002.** The TRIAGE-flow narrative rewrite (`Triage` term, line 146; T1/T2/T3 menu) is **feature-002**; the recipe-catalog glossary rewrite (Seed Catalog term, line 168) is **feature-003**. | KB |
| `.aid/knowledge/pipeline-contracts.md` | 608 (`applies-to: bug-fix  # bug-fix | small-refactor | single-doc | small-new-feature | *` inline comment in the Recipe File Front-matter Contract) | Update the inline enum comment to `# bug-fix | new-feature | refactor | *`. | KB |

**Count: 7 files** edited directly by feature-001 —
**3 canonical** (`recipes/README.md`, `templates/recipe-template.md`,
`templates/work-state-template.md:18`) + **1 test** (`tests/canonical/test-parse-recipe.sh`)
+ **3 KB** (`schemas.md`, `domain-glossary.md`, `pipeline-contracts.md`).

> **Not in scope:**
> - **`state-triage.md` and all interview state-machine bodies** (`state-triage.md`,
>   `state-condensed-intake.md`, `state-task-breakdown.md`, `state-lite-done.md`,
>   `lite-to-full-escalation.md`) — feature-002 (the CONSUMER). The four files other than
>   `state-triage.md` carry **zero** old-enum tokens (only LITE-* sub-path labels, a feature-002
>   concern); `state-triage.md` carries old tokens that feature-002's wholesale rewrite emits as
>   new tokens.
> - **The five recipe FILES** (`method-refactor.md`, `add-crud-endpoint.md`,
>   `write-release-note.md`, `bug-fix.md`, `add-unit-test.md`) — feature-003 (the INSTANCES).
> - **`work-state-template.md:19`** (Sub-path enum) and **`domain-glossary.md:149`** (LITE-DOC
>   row) — feature-002 (sub-path fate).

### Enum Rename Map

Exact old→new, by token:

| Old token | New token | Rationale |
|-----------|-----------|-----------|
| `bug-fix` | `bug-fix` | **Unchanged.** Value already conventional. |
| `small-refactor` | `refactor` | Drop the `small-` qualifier (lite-path scope is already implied). |
| `small-new-feature` | `new-feature` | Drop the `small-` qualifier. |
| `single-doc` | *(eliminated)* | Docs & reports fold into `new-feature` (add) / `refactor` (change). No replacement enum value. |
| `*` | `*` | **Unchanged.** Cross-type wildcard. |

Resulting `applies-to` enum: **`{ bug-fix, new-feature, refactor, * }`**.

**Sub-path labels** (`LITE-BUG-FIX` / `LITE-DOC` / `LITE-REFACTOR` / `LITE-FEATURE`) — these
are *derived from* the workType but are **not** the `applies-to` enum:

- `LITE-BUG-FIX` (← bug-fix): unchanged.
- `LITE-REFACTOR` (← refactor): label unchanged; only its source workType token renames.
- `LITE-FEATURE` (← new-feature): label unchanged; only its source workType token renames.
- `LITE-DOC` (← single-doc): the **eliminated** sub-path. Because `single-doc` no longer
  exists, LITE-DOC has no source workType and should fold away — docs become
  add/change-documentation work routed under LITE-FEATURE / LITE-REFACTOR. **This fold is
  entirely feature-002's responsibility** (the CONSUMER): feature-002 rewrites the T3 menu +
  the workType→Sub-path table that produces LITE-DOC, owns `work-state-template.md:19` (Sub-path
  enum) and `domain-glossary.md:149` (LITE-DOC row), and rewrites the LITE-DOC sub-path
  interview body (`state-condensed-intake.md` § LITE-DOC). **feature-001 touches no LITE-DOC
  artifact at all** — it only removes `single-doc` from the `Work Type` / `applies-to` *enum*
  lines it owns (work-state-template:18, README/template enums, schemas.md, pipeline-contracts.md,
  domain-glossary `workType` term:147).

`bug-fix` as a value vs. `bug-fix` as a future recipe id: note (per feature-003) the recipe
id `fix-application` is deliberately distinct from the `bug-fix` **workType** it carries in
`applies-to:`. feature-001 does not author recipes, so this distinction is informational only.

### `summary:` Schema Addition

**What:** a new optional `summary:` front-matter field on recipes — a one-line free-form
string describing the recipe, used by the description-first TRIAGE (feature-002) to match a
user's free-form work description to a recipe, and by the catalog listing.

**Where documented:**

1. `canonical/recipes/README.md` § YAML Front-Matter — add a `summary:` row to the fields
   table (currently lines 61–66, four rows) and show it in the example block (lines 50–57).
   State explicitly that it is **optional and agent-read only** (no parser enforcement).
2. `canonical/templates/recipe-template.md` — add a `summary:` line to the front-matter
   example (lines 1–6) and to the authoring-guide fields table (lines 81–86), with a
   one-line note: "optional; one-line description; read by TRIAGE for description→recipe
   matching; not validated by `parse-recipe.sh`."

**Format:** a single line, e.g. `summary: Fix a known defect and add a regression test.`
Plain string (no slot tokens needed; it is not rendered into the work SPEC).

**Coexistence with required fields & no-enforcement proof:** the four required fields
(`name`, `applies-to`, `slot-count`, `task-count`) are unchanged and still required.
`parse-recipe.sh` reads front-matter via `parse_frontmatter()`
(`canonical/scripts/interview/parse-recipe.sh:158–181`): it `grep`s for **exactly** the four
known keys (lines 164–167) and dies only if one of those four is empty (lines 169–172). Any
other front-matter line — including `summary:` — is simply **never read**: the awk extractor
(line 162) captures all lines between the `---` fences, but only the four `grep -E '^<key>:'`
calls consume them. There is **no enum check** on `applies-to` anywhere in the script (line
170 only asserts non-empty), and **no "unknown field" rejection**. Therefore adding
`summary:` requires **zero** script change and `--validate` / `--render` / `--list` behave
identically. (KB corroborates: `schemas.md §5` parsing rules — "Unknown fields tolerated
(forward-compatible)" — and the `discovery-reviewer` frontmatter contract both already
assume unknown-field tolerance.)

### Test-Fixture Updates

The smoke test embeds recipe fixtures as heredocs; two carry an old enum token:

- `tests/canonical/test-parse-recipe.sh:145` — `applies-to: small-new-feature` (EXACT_RECIPE
  fixture) → `applies-to: new-feature`.
- `tests/canonical/test-parse-recipe.sh:205` — `applies-to: small-new-feature` (MULTI_RECIPE
  fixture) → `applies-to: new-feature`.

No other fixture token needs changing: the other fixtures already use `applies-to: bug-fix`
(lines 66, 323, 350, 373, 395, 414), `applies-to: *` (line 291, ESCAPE_RECIPE), or
`applies-to: "*"` (line 882, Unit 20). None of the 111 assertions test the *literal string*
`small-new-feature` — they assert exit codes, slot/task counts, render output, and the
quoted-star contract — so changing the two fixture tokens keeps every assertion green (AC7).
The smoke test also validates the **real seed recipes** in Units 15–19
(`canonical/recipes/{bug-fix,write-release-note,method-refactor,add-crud-endpoint,add-unit-test}.md`)
via `--validate`, which only checks structural correctness (slot/task counts, block presence)
and is **agnostic to the `applies-to` value**. Those seed-recipe files are feature-003's to
edit (their token re-targets and renames land there); whether their tokens are old or new,
Units 15–19 stay green regardless — so feature-001's fixture edits are independent of the
recipe-file work.

### KB Updates (AC6 — enum scope)

Edit exactly the enum references, leaving TRIAGE-flow narrative (feature-002) and
recipe-catalog prose (feature-003) untouched:

- `schemas.md:180` → `{`bug-fix`, `new-feature`, `refactor`}` (Work Type enum).
- `schemas.md:369` → `One of `bug-fix`, `new-feature`, `refactor`, or `*``.
- `pipeline-contracts.md:608` → inline comment `# bug-fix | new-feature | refactor | *`.
- `domain-glossary.md:147` (`workType` term) → ``bug-fix | new-feature | refactor``.
- `domain-glossary.md:149` (`LITE-DOC` term) → **NOT edited by feature-001.** This row's fate
  (whether LITE-DOC stays once `single-doc` is gone) is a sub-path decision owned by
  feature-002. Deferring it keeps feature-001 from half-stating a sub-path story.
- `domain-glossary.md:150–151` (`LITE-REFACTOR`/`LITE-FEATURE`) → replace `small-refactor`
  with `refactor` and `small-new-feature` with `new-feature` in the term text.

KB changelog: add a dated entry to each edited KB doc's `changelog:` frontmatter recording
"work-001 feature-001 — lite work-type enum collapsed 4→3 (single-doc eliminated); recipe
`summary:` field added."

### Clean-break note (REQUIREMENTS §7)

No alias / read-compat / migration shim. Only `{bug-fix, new-feature, refactor}` are valid
after this change. Any in-flight lite work whose `STATE.md ## Triage` records an old
`Work Type` value (`small-refactor` / `single-doc` / `small-new-feature`) is **reset and
re-triaged** — it is not auto-migrated. Per REQUIREMENTS §8 the assumption is that no such
in-flight lite work currently exists, so the clean break is safe at this time.

### Ownership boundary (feature-001 ↔ feature-002/003) — RESOLVED

The orchestrator owns all three features and specs them sequentially in one work/delivery.
The boundary is a clean, non-overlapping partition by **role**:

- **feature-001 (this) = the enum DEFINITION.** The schema (recipe README + recipe template),
  the generic `work-state-template.md:18` Work Type enum line, the canonical test fixtures, and
  the KB enum references. Plus the `summary:` schema addition. Nothing else.
- **feature-002 = the CONSUMER.** Owns **all** of `state-triage.md` (its description-first
  rewrite replaces the T3 menu + workType→Sub-path tables wholesale, naturally emitting only
  new-enum tokens) and the sub-path interview bodies, plus every sub-path-fate artifact:
  `work-state-template.md:19` (Sub-path enum) and `domain-glossary.md:149` (LITE-DOC row).
- **feature-003 = the recipe-file INSTANCES.** Owns the recipe **catalog** — the five existing
  recipe files (`method-refactor.md`, `add-crud-endpoint.md`, `write-release-note.md`,
  `bug-fix.md`, `add-unit-test.md`) including their `applies-to:` tokens, their filenames,
  their `name:` fields, and the `write-release-note`→`add-docs`/`add-report` re-target.

There is **no co-ownership and no overlap**: feature-001 does not edit `state-triage.md`, does
not edit any recipe file, and does not edit any sub-path artifact. Because all three land in the
same work/delivery, there is no broken interim state once the set completes.

**AC1 verification point.** feature-001 satisfies AC1 for the files **it owns**. The work-level
"zero old enum tokens across **all** canonical files" sweep passes only after the **last**
feature (feature-003) lands, because `state-triage.md` (feature-002) and the recipe files
(feature-003) still carry old tokens until their owning features complete. The PLAN must run the
repo-wide sweep as a work-level gate after feature-003, and must **not** fault feature-001 for
not achieving the full-repo sweep alone.

### Render & Verification

Run in order; all must pass:

1. **Feature-001-scoped enum sweep returns zero hits in the files feature-001 owns.** Confirm
   no old tokens remain in feature-001's seven files:
   ```sh
   grep -nE 'small-refactor|small-new-feature|single-doc' \
     canonical/recipes/README.md \
     canonical/templates/recipe-template.md \
     canonical/templates/work-state-template.md \
     tests/canonical/test-parse-recipe.sh \
     .aid/knowledge/schemas.md .aid/knowledge/pipeline-contracts.md
   grep -nE 'small-refactor|small-new-feature' .aid/knowledge/domain-glossary.md   # line 149 (single-doc/LITE-DOC) is feature-002's
   ```
   Expect no output from the first grep, and no `small-*` hits from the second (a `single-doc`
   on domain-glossary:149 is **expected** until feature-002 lands). **Work-level note:** the
   repo-wide sweep
   `grep -rn -E 'small-refactor|small-new-feature|single-doc' canonical/ tests/ .aid/knowledge/ | grep -v 'reviewer-ledger-schema.md'`
   returning zero is a **work-level gate run after feature-003**, not a feature-001 gate —
   `state-triage.md` (feature-002) and the recipe files (feature-003) still carry old tokens
   until then. (The `reviewer-ledger-schema.md:82` "single-doc cosmetic issue" `[LOW]` severity
   description is benign prose and must remain at all times.)
2. **Smoke test green:** `bash tests/canonical/test-parse-recipe.sh` exits 0 with all
   assertions passing (AC7). Units 15–19 validate the on-disk seed recipes structurally and are
   agnostic to `applies-to` — they stay green whether those files carry old or new tokens (their
   token edits are feature-003's).
3. **`summary:`-tolerance proof:** `bash canonical/scripts/interview/parse-recipe.sh --validate
   canonical/recipes/bug-fix.md` (after adding a `summary:` line to that recipe) prints
   `OK: all checks passed` and exits 0 — demonstrating the validator ignores the new field.
4. **Re-render to all 5 install trees:** run `/aid-generate`; then the deterministic verify
   (`verify_deterministic.py`) asserts the recipe-template / work-state-template renders are
   byte-identical across `antigravity`, `claude-code`, `codex`, `copilot-cli`, `cursor`. The
   rendered `applies-to` / `summary:` / Work-Type-enum lines must match canonical (recipes and
   templates use the passthrough renderer — no frontmatter injection — so canonical bytes flow
   through unchanged).
5. **Profile-tree sweep for feature-001's files:** confirm the re-render carried the rename
   outward into the install trees for the templates feature-001 owns (recipe-template,
   work-state-template) — no stale old-enum tokens in those rendered files. (The full
   profile-tree sweep over `state-triage.md` and the recipe files is a work-level check after
   feature-002 / feature-003 re-render their owned sources.)

### Resolved decisions (formerly open questions)

All boundary questions are **resolved** by the orchestrator's role-based partition (definition /
consumer / instances). No Required open question remains; this spec is ready for an A gate.

- **OQ-1 (ownership of `state-triage.md`) — RESOLVED.** feature-002 owns **all** of
  `state-triage.md`. feature-001 does **not** edit it. feature-002's description-first rewrite
  replaces the T3 menu + workType→Sub-path tables wholesale and naturally emits only new-enum
  tokens. Because feature-001 + feature-002 land in the same work/delivery, there is no broken
  interim once both complete.
- **OQ-2 (`write-release-note` re-target) — RESOLVED / eliminated.** The five recipe **files**
  (including `write-release-note.md` and its re-target as part of
  `write-release-note`→`add-docs`/`add-report`) belong to **feature-003**. feature-001 does not
  edit any recipe file, so the re-target question does not arise here at all.
- **OQ-3 (LITE-DOC sub-path fate) — RESOLVED.** The LITE-DOC sub-path fate is **feature-002's**.
  feature-001 touches no sub-path artifact: not the interview body
  (`state-condensed-intake.md`), not `work-state-template.md:19` (Sub-path enum), and not
  `domain-glossary.md:149` (LITE-DOC row). feature-001 edits only the `Work Type` enum
  (work-state-template:18) and the `workType` term enum (domain-glossary:147) +
  LITE-REFACTOR/LITE-FEATURE token text (150–151). A surviving `single-doc`/LITE-DOC reference
  in a feature-002/003-owned file is **not** a feature-001 AC1 miss.
- **AC1 verification point (note, not a question).** feature-001 satisfies AC1 for the files it
  owns; the repo-wide "zero old enum tokens across all canonical files" sweep is a work-level
  gate verified after feature-003. The PLAN must reflect this so the reviewer does not fault
  feature-001 for the full-repo sweep.
- **Low risk — fixture coverage:** the smoke test never asserts the literal old strings, so the
  two fixture edits cannot silently break an assertion; still, re-run the full suite (not a
  subset). Units 15–19 validate the on-disk seed recipes structurally and are agnostic to
  `applies-to` (their token edits are feature-003's), so they stay green regardless.
