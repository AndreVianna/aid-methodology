# task-019: `scan-source.sh` qualification settling and the three output streams

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

**Type:** IMPLEMENT

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-018

**Scope:**

- Add feature-004's Feature Flow **steps 5–8** to the existing
  `canonical/aid/scripts/graph/scan-source.sh`, **without disturbing task-018's steps 1–4** — the
  `scan-source.sh` serialisation is 018 -> 019.
  5. **First-match qualification.** For each surviving path evaluate the `declared` carriers, then
     convention membership, then executable-header presence, in that fixed order, stopping at the
     first match, so a node's evidence is the strongest available and the record is a pure function
     of disk state that cannot flip between runs. A path with no match is held for step 6.
  6. **Settle `depended-upon`.** Scan the bytes of the step-5 nodes for D5 references, emitting
     `observations.tsv`. A held path receiving at least one inbound reference qualifies as
     `depended-upon`, with the citing path plus the matched literal as evidence. Iterate to a fixed
     point — a newly qualified node's own references can qualify another — bounded by the node count,
     which terminates because the qualified set only grows. Fixed-point iteration is what makes the
     result independent of traversal order and therefore reproducible.
  7. **Drop the residue.** Every still-unqualified path becomes a `candidates.tsv` row with
     `drop_reason` `no-rule-match`. **File existence alone never qualifies**, and this step is where
     that requirement is actually enforced.
  8. **Emit** the three streams into `.aid/.temp/graph/`, each tab-separated, header-less,
     `LC_ALL=C`-sorted and LF-only: `nodes.tsv` (D1's six fields, keyed on `node_id`),
     `observations.tsv` (D5's four fields), `candidates.tsv` (D6's four fields). Print a one-line
     `[scan] N nodes, M observations, K candidates` summary to stderr. Exit `0` on a successful scan,
     `1` on a write failure, `2` on a usage or environment error.
- **The single-writer `no-inferred-node` guard.** This is the invariant features 006 and 007 are both
  told to rely on, so it must be mechanically held rather than asserted:
  - `nodes.tsv` is written through **exactly one named writer function with a single call site**.
  - That function **rejects any row whose `evidence_provenance` is not `declared` or `derived` and
    exits non-zero** — it does not filter the row. Such a row is a scanner bug, not a data
    condition, so it must abort.
  - `candidates.tsv` is the only channel from the rules to feature-005's agent pass, and it is
    write-only from the scanner's side: **no code path reads a candidate back into the node set.**
  - Consequence to record in the script header, so downstream features need not re-derive it:
    feature-006 needs no "drop `int:` nodes qualified only by inference" gap-predicate filter,
    because the set it would filter cannot contain such a node; and feature-007's node record needs
    no qualification-provenance field for this purpose.
- **Reference resolution never guesses** (D5): a full repo-relative path matching an enumerated node
  resolves to that node; a **basename** matching exactly one enumerated node after exclusions
  resolves to that node — which works precisely because Class 1 removed the render copies, leaving
  one surviving `build-kb-index.sh` out of eight on disk; a basename matching more than one or zero
  becomes a `candidates.tsv` row with `drop_reason` `ambiguous-basename` or `unresolved-reference`.
  Never a guess, never a row.
- The scanner **emits observations without typing them**: it never consults the relation vocabulary
  and never writes a relationship row. `derive-edges.sh` (task-022) does all typing.
- No `nodes.tsv` field carries a timestamp, an absolute path, a line number, or a file size — that is
  what makes the stream, and therefore the `derived` half of `relationships.md`, byte-identical
  across runs (FR-32).
- **Out of scope:** steps 1–4 (task-018 — do not modify); typing observations (task-022); the `kb:`
  node set, which feature-005 owns (task-021); the fixture tree and the four suites
  (tasks 032, 033).

**Acceptance Criteria:**

- [ ] Qualification is first-match in the fixed order `declared` carriers -> convention membership ->
      executable header, so a path qualified by several clauses records the strongest evidence and
      the `qualifier` field cannot flip between runs.
- [ ] `depended-upon` settles by iteration to a fixed point bounded by the node count, and the
      resulting node set is byte-identical regardless of the order candidate paths are visited in —
      demonstrable by re-running over a shuffled candidate list on the fixture tree.
- [ ] A path matching no clause appears in `candidates.tsv` with `drop_reason` `no-rule-match` and
      does **not** appear in `nodes.tsv`: file existence alone never qualifies.
- [ ] The three streams are written to `.aid/.temp/graph/` with D1 / D5 / D6's exact field sets,
      tab-separated, header-less, `LC_ALL=C`-sorted, LF-only.
- [ ] No `nodes.tsv` field carries a timestamp, an absolute path, a line number, or a file size; two
      consecutive scans of an unchanged fixture tree produce byte-identical streams.
- [ ] `nodes.tsv` is written through exactly one named writer function with a **single call site** —
      greppable, and named in the script header — and no other code path appends to that file.
- [ ] That writer **exits non-zero** on any row whose `evidence_provenance` is not `declared` or
      `derived`, naming the offending row, rather than filtering it. A crafted bad row driven through
      the writer in a test makes the scan abort — the guard is exercisable, not aspirational.
- [ ] No code path promotes a `candidates.tsv` row to a `nodes.tsv` row; `candidates.tsv` is
      write-only from the scanner's side.
- [ ] `tests/canonical/test-graph-node-provenance.sh` (task-033) can assert, over both the fixture
      tree and this repository, that field 6 of every `nodes.tsv` row is `declared` or `derived`, and
      that no `candidates.tsv` row with `candidate_kind` = `node` has a `subject` appearing as a
      `nodes.tsv` `node_id` — the output shape this task emits makes both assertions expressible
      without any extra instrumentation.
- [ ] Basename resolution is single-valued or it is not a row: an ambiguous or unresolvable reference
      becomes a `candidates.tsv` row with `ambiguous-basename` / `unresolved-reference`.
- [ ] The scanner writes no relationship row and reads no relation vocabulary — provable by grep over
      the script for any vocabulary member or any read of `relation-vocabulary.yml`.
- [ ] Exit codes are `0` success / `1` write failure / `2` usage or environment error, and stderr
      carries the `[scan] N nodes, M observations, K candidates` line.
- [ ] `git diff` shows task-018's steps 1–4 unchanged.
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden** — the vehicle is `tests/canonical/test-*.sh`, which the one-type rule
      forces into separate TEST tasks; the named suites land in **task-032**
      (`test-source-enumeration.sh`) and **task-033** (`test-graph-single-scanner.sh`,
      `test-graph-node-partition.sh`, `test-graph-node-provenance.sh`).
- [ ] Only `canonical/` is edited; nothing under `profiles/` or `.claude/` is hand-edited (the FULL
      render is task-044).
- [ ] The code baseline holds (`.aid/knowledge/coding-standards.md`) and the delivery gate's
      `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.
