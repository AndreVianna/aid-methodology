# task-002: Re-point the KB-index oracles at the new table shape and verify the restructure

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. This is the FLAT layout: there is no sibling
task-002/STATE.md -- this task's mutable cells live in the work-root STATE.md, section
`### Tasks lifecycle`.
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

**Source:** work-010-refactor -> delivery-001

**Depends on:** task-001

**Scope:**
- **`tests/canonical/test-build-kb-index.sh` -- BI01.** Update the header assert at L102 to
  `| Document | Audience | Tags | See-instead | Objective | Summary |` and the separator assert at
  L104 to `|----------|----------|------|-------------|-----------|---------|`. Both move
  together: the separator assert is required by AC-1 even though FR-12 names only L102. The BI01
  cell-content asserts (L92-99) are order-agnostic and stay as they are; BI01's baseline count of
  10 tagged assertions is unchanged.
- **`tests/canonical/test-build-kb-index.sh` -- BI13.** Four edits:
  1. **INVERT, never delete,** the assert at L403:
     `assert_file_contains "$OUT13" "## Extension"` becomes
     `assert_file_not_contains "$OUT13" "## Extension"` (the helper exists --
     `tests/lib/assert.sh` `assert_file_not_contains`), with a message describing the new
     expectation. **Deleting it instead would drop BI13 from 6 tagged assertions to 5 and fail
     the coverage-parity gate** -- `tests/coverage-baseline.tsv` is committed and therefore
     ENFORCING, and it pins `test-build-kb-index.sh  BI13  6`.
  2. Add a NEW assertion that `ext-doc.md`'s row is INSIDE the Primary table -- i.e. the
     `[ext-doc.md](../knowledge/ext-doc.md)` row falls in the range between
     `## Primary - load-bearing knowledge` and the next `## ` heading in `$OUT13`, not merely
     present in the file (L408 already asserts mere presence, so an assert that only re-checks
     presence asserts nothing new). A net-add is what the coverage gate permits; it needs no
     accept-list row and no baseline re-bootstrap.
  3. Reword the section comments at L18 (the BI13 line of the assertion roll-call) and L371 (the
     BI13 banner) -- "category grouping" now means primary/meta with `extension` folded into
     Primary.
  4. **Retain the three-category `kb13` fixture verbatim**, including the `ext-doc.md` block at
     L389-395, so the fold-in is actually exercised. Asserts at L401-402 and L406-408 are
     unchanged. If the `ext-doc.md` fixture's `summary:` prose (L393) is reworded for accuracy,
     it must remain fixture data only -- no assertion may start depending on it.
- **`tests/canonical/test-build-kb-index.sh` -- BI16.** Update the `grep -c` pattern at L468 to
  the new header string and the expected count at L469 from `3` to `2`. **The assert message at
  L469 also lies after this change** -- it reads "(3 categories = 3 headers)"; reword it to match
  the two emitted sections. **The comment at L467 also lies** -- it reads
  `# kb13 has all three categories; each must have exactly one header row.`, which the Extension
  fold-in falsifies; reword it (kb13 still declares three categories, but only two now emit a
  header row). **The comments at L21 and L465 carry the SAME falsified framing and are in scope
  for the identical reword** -- L21 reads
  `#   BI16  Table header row emitted once per category (6-column header + separator).` and L465
  reads `# BI16  Table header row emitted once per category (6-column header).`; both say "once
  per category", which the fold-in makes false for exactly the reason L467/L469 are false (kb13
  declares three categories but emits two headers). Reword both to "once per *emitted* section",
  keeping each line's existing suffix (`6-column header + separator` at L21, `6-column header` at
  L465) -- the header is still 6 columns, only its order changed, so that part stays. All four
  comment/message sites (L21, L465, L467, L469) move together. BI16 stays at 1 tagged assertion.
- **`tests/canonical/test-kb-forward-authored-marker.sh` -- FI03.** Update the `grep -qF` header
  string at L381 to the new order. The "6-column ... schema unchanged" framing in the surrounding
  comment and in the pass/fail messages stays true and stays as-is.
- **Do NOT touch** `canonical/aid/scripts/kb/build-kb-index.sh`, any rendered twin,
  `.aid/knowledge/INDEX.md`, or `tests/coverage-baseline.tsv` -- if the baseline needs editing,
  that is a signal the BI13 edit was done wrong (see the invert-not-delete rule above).
- **Then run the verification sweep** and report results; if anything fails on first run, that is
  a finding to document, not to hide. Read every suite total from the script's own summary line,
  never by grepping its stdout.

**Acceptance Criteria:**
- [ ] **AC-11 (oracles).** `bash tests/canonical/test-build-kb-index.sh` and
      `bash tests/canonical/test-kb-forward-authored-marker.sh` each report 0 failures in their
      own summary line -- including BI01's new header and separator asserts, BI13's
      absent-Extension and Primary-placement asserts, BI16's new header pattern with expected
      count 2, and FI03's new header string.
- [ ] **AC-11 (no new failures).** The full canonical suite (`bash tests/run-all.sh`) shows no
      new failures against the pre-change baseline task-001 captured -- compared suite-by-suite
      against that file, not from memory.
- [ ] **Coverage-parity gate green.** `bash tests/coverage-parity.sh diff --baseline
      tests/coverage-baseline.tsv --allow tests/coverage-rehome-allowlist.tsv --accept
      tests/coverage-accepted-removals.tsv --collect` (the CI invocation) exits 0 with all three
      input files unmodified: BI13 still emits at least its 6 tagged assertions, BI01 still 10,
      BI16 still 1. Never pass `--allow-missing-runtime` for a gating run.
- [ ] **Each added/changed assertion traces to a criterion and is non-vacuous.** BI01 header +
      separator -> AC-1; BI13 inverted assert -> AC-3; BI13 Primary-placement assert -> AC-4;
      BI16 count -> AC-6; FI03 -> AC-1. The BI13 Primary-placement assert must FAIL against the
      pre-task-001 generator (where `ext-doc.md` renders under its own `## Extension` heading);
      an assertion that passes both before and after asserts nothing.
- [ ] **Deterministic and clean.** Two runs of each edited suite over the same fixtures produce
      identical PASS/FAIL sets and identical counts; every fixture stays under the suite's
      existing `mktemp -d` base and is removed on exit including on failure; no assertion depends
      on execution order or on a previous run's residue; the working tree is untouched by a test
      run.
- [ ] **AC-12 (stale references).** A repo-wide grep **excluding `.git/`, `.aid/works/`, and
      `.aid/.temp/`** (same reason as task-001 AC-1: this work's own documents and its review
      ledger must quote the old strings, and a literal grep honours no ignore rules) for
      the old header string, the old separator string, `## Extension - project-specific`, and the
      prose phrase `Objective, Summary, Tags, See-instead, and Audience` returns zero hits. The
      `.aid/works/` and `.aid/.temp/` exclusions are mandatory: this work's own REQUIREMENTS.md /
      SPEC.md / BLUEPRINT.md / task DETAIL.md files, and its review ledger under
      `.aid/.temp/review-pending/`, necessarily quote the old strings, so an unscoped repo-wide
      grep always fails and is not evidence of a defect.
- [ ] **AC-12 (no positional consumer).** A companion grep confirms no consumer parses
      `.aid/knowledge/INDEX.md` positionally by column index, and that nothing outside the two
      oracles updated here greps for the `## Extension` heading.
- [ ] **AC-9 / AC-10 re-verified after the test edits.** The `kb-hygiene` "INDEX.md is fresh"
      regenerate-and-diff check still produces empty output, `bash
      tests/canonical/test-dogfood-byte-identity.sh` exits 0, and `git status --porcelain` shows
      no render drift under `profiles/`, `.claude/`, or `.cursor/`.
- [ ] All section-6 quality gates pass.
