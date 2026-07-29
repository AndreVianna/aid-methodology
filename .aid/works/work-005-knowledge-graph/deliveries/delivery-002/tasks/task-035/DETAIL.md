# task-035: `test-validate-relationships.sh` and the synthetic external-sources fixture

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

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-016

**Scope:**

- Create `tests/canonical/test-validate-relationships.sh`: "one negative fixture per validator,
  proving each check fires, plus a clean-pass fixture" (feature-003 Layers table).
- **One negative fixture per validator, V1 through V12**, each asserted to produce the tagged
  finding in the `[TAG] <doc>: <message>` form and to carry the ledger severity feature-003's
  Validators table assigns:
  - `V1` `[REL-SHAPE]` `[HIGH]` -- a header or delimiter row not byte-equal to D1's form, a data
    row without eight cells, wrong D1 padding, an embedded newline, an unescaped `|`, and a CRLF
    ending. Assert the documented consequence: **the row is reported and excluded from V2-V8,
    V11 and V12, and the run continues** -- it is never guessed at.
  - `V2` `[REL-UNRESOLVED]` `[HIGH]` -- a `kb:` doc outside the scan set; a `kb:` anchor that is
    not among that doc's recomputed heading slugs; an `int:` path that does not exist from the
    repo root; an `ext:` key not registered. The finding names the id and which resolution step
    failed.
  - `V3` `[REL-VOCAB]` `[HIGH]` -- a non-member relation label.
  - `V4` `[REL-PAIR]` `[HIGH]` -- an `(S2T, T2S)` pair that is not a vocabulary pair in either
    orientation. **Plus the positive control that a naive validator gets wrong**: a symmetric
    relation's row where `S2T == T2S` is **valid** and must produce no finding.
  - `V5` `[REL-DUPLICATE]` `[HIGH]` -- two rows sharing a `rel_row_key`, both as a verbatim
    repeat and as a separately written inverse; the finding names the key and both row ordinals.
  - `V6` -- a `Provenance` value outside `declared`/`derived`/`inferred`, and an empty one.
  - `V7` -- a narrowed `int:<path>#<symbol>` id present in the table, rejected on granularity
    grounds (the grammar admits it; the emitted table must not).
  - `V8` `[REL-NAME]` `[HIGH]` -- a name that is not `rel_display_name` for a `kb:`/`ext:` id;
    the same id carrying two different names anywhere in the file; an empty name.
  - `V9` `[REL-FRONTMATTER]` `[HIGH]` -- D8's block absent, not the first content in the file, or
    missing/empty in any of `kb-category`, `source`, `generator`, `objective`, `summary`, `tags`;
    a multi-line or pipe-carrying `objective`/`summary`; a **timestamp** appearing in the table,
    in any row, or in the `AUTO-GENERATED` marker. Assert the tolerance half too: an unknown key
    and a sibling-feature-owned key (`graph_inputs_digest`, `graph_generated_at`, `kb_gaps`) are
    tolerated and not validated.
  - `V10` `[REL-ORDER]` `[HIGH]` -- a row out of D7's sort order, and a class-0 row that is not
    part of the contiguous prefix; the finding names the first out-of-order ordinal.
  - `V11` `[REL-OBSERVATION]` `[HIGH]` -- free prose in a class-0 row's `Observation`, and a bare
    `file.ext:LINE` citation in any row. Assert the mechanical predicate: a class-0 `Observation`
    is empty **or** its first whitespace-delimited token matches
    `[A-Za-z0-9_./-]+\.(md|sh|py|mjs|js|ts|yml|yaml|json|toml|txt|ps1)`. Assert the
    bare-line-citation discrimination reused verbatim from `kb-citation-lint.sh`: a colon
    followed by digits is a violation **unless** the next character is a letter, a `-` plus a
    letter, or a `.` plus a digit (an IP or a version).
  - `V12` `[REL-ENDPOINT]` `[LOW]` -- a row whose `<source-prefix>-><target-prefix>` pair is not
    in the chosen relation's `endpoint_kinds`. Assert it is **advisory and never gates**: the
    finding is emitted, but a file whose only finding is `V12` still exits `0`.
- A **clean-pass fixture** producing zero findings, and assertions on the run trailer and exit
  scheme: the `Checked/Findings` trailer is printed, and the `0` / `1` / `2` exit contract holds
  (`2` reserved for a configuration error such as an absent or malformed vocabulary, so a
  configuration fault is never reported as an artifact defect).
- **Build the synthetic `external-sources.md` fixture.** This is the agreed evidence for AC-1's
  `ext:` branch (Q4): this project's real `.aid/knowledge/external-sources.md` has **zero
  registered entries** and would satisfy the criterion vacuously. The fixture carries a
  `## Sources` section with a GFM table whose first cell is a key rendered as inline code, and
  supplies **both resolvable and deliberately unresolvable keys**. **The key set is fixed by owner
  decision (2026-07-28) and is not this task's to choose:** register **`wcag-22-aa`** and
  **`idv-accessible-charts`** in the table as resolvable, and reference **`absent-source`** as an
  `ext:` id deliberately absent from the table so it must fail `V2`. Task-002 (delivery-001) cites
  `ext:wcag-22-aa` in its worked KB-to-external vocabulary row, so **these two sides must match
  exactly** — if this fixture renames a key, task-002's worked row becomes unresolvable. Assert the
  resolver's predicate exactly:
  inside `## Sources`, a line matching `^\|[[:space:]]*` + a backticked key +
  `[[:space:]]*\|` registers that key -- and a key mentioned only in prose does not. The fixture
  is self-built under `mktemp -d` and depends on no work folder's contents (A-6).
- Out of scope: the D9 library and loader-rejection suite (**task-034**); the validators
  themselves (task-016); the schema and vocabulary loaders (tasks 014, 015); any change to
  `.aid/knowledge/external-sources.md` -- `/aid-graph` is read-only with respect to the KB
  (FR-10) and that file's writer is `/aid-discover`'s ELICIT state.
- Discovered by the `tests/canonical/test-*.sh` glob with **no edit to `tests/run-all.sh`**;
  sources `tests/lib/assert.sh`; uses the `ID + description` label convention of
  `tests/canonical/test-guardrails-d012.sh`.

**Acceptance Criteria:**

- [ ] `tests/canonical/test-validate-relationships.sh` exists, sources `tests/lib/assert.sh`,
      uses the `ID + description` label convention, and is discovered by the glob with no edit to
      `tests/run-all.sh`.
- [ ] There is at least one negative fixture for each of `V1`-`V12`, and each is asserted to
      emit its own tag in the `[TAG] <doc>: <message>` form.
- [ ] `V1`'s documented consequence is asserted: the malformed row is reported and excluded from
      `V2`-`V8`, `V11`, `V12`, and the run continues over the remaining rows.
- [ ] `V4`'s symmetric positive control is asserted: a row with `S2T == T2S` backed by a
      `symmetry: symmetric` entry produces **no** finding.
- [ ] `V9` is asserted for every required field, for a multi-line or pipe-carrying
      `objective`/`summary`, for a timestamp anywhere in the table or the `AUTO-GENERATED`
      marker, and for the tolerance of unknown and sibling-owned keys.
- [ ] `V11`'s durable-anchor predicate and its `kb-citation-lint.sh` bare-line-citation
      discrimination (including the IP and version exemptions) are both asserted.
- [ ] `V12` is asserted to emit at `[LOW]` and to **not** change the exit status -- a file whose
      only finding is `V12` exits `0`.
- [ ] The clean-pass fixture produces zero findings and exit `0`; the `Checked/Findings` trailer
      is asserted; exit `1` on a gating finding and exit `2` on a configuration error are both
      asserted.
- [ ] A **synthetic `external-sources.md`** fixture exists, built by the suite under
      `mktemp -d`, carrying a `## Sources` GFM table with at least one resolvable inline-code key
      and at least one `ext:` id whose key is deliberately unregistered.
- [ ] The resolvable `ext:` id passes `V2` and the unregistered one fails it, so AC-1's `ext:`
      branch is proven non-vacuously.
- [ ] A key mentioned only in prose (not as a table row's first inline-code cell) is asserted
      **not** registered.
- [ ] `.aid/knowledge/external-sources.md` is not read as the fixture and is not modified.
- [ ] No fixture reads any path under `.aid/works/` (A-6).
- [ ] **Tests are deterministic** -- no wall-clock dependence, no network, no ordering
      dependence; `LC_ALL=C` on every sort; repeated runs agree.
- [ ] **Clean setup/teardown** -- every fixture is created under `mktemp -d` and removed on exit
      including on failure (`trap`); `git status --porcelain` is clean afterwards.
- [ ] **Every acceptance criterion from feature-003 that this suite carries is covered**: AC-1
      (all three id branches, `ext:` via the synthetic fixture), AC-2 (`V3`, `V4`), AC-3 (`V5`),
      AC-4 (`V6`), AC-18 (`V9`), and AC-5's support checks (`V10`, `V11`).
- [ ] The suite passes under `HOME="$(mktemp -d)" bash tests/run-all.sh`, and no existing suite
      regresses.
