# task-016: `validate-relationships.sh` validators V1-V12

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

**Depends on:** task-014, task-015

**Scope:**

- Create `canonical/aid/scripts/graph/validate-relationships.sh`: the twelve rubric-tagged checks
  feature-003 defines, run over `.aid/knowledge/relationships.md` or a fixture supplied by `--file`.
  It sources `relationship-schema.sh` (tasks 014, 015) and re-derives nothing those functions
  already provide.
- The twelve, by tag: **V1** `[REL-SHAPE]`, **V2** `[REL-UNRESOLVED]`, **V3** `[REL-VOCAB]`,
  **V4** `[REL-PAIR]`, **V5** `[REL-DUPLICATE]`, **V6** `[REL-PROVENANCE]`, **V7**
  `[REL-GRANULARITY]`, **V8** `[REL-NAME]`, **V9** `[REL-FRONTMATTER]`, **V10** `[REL-ORDER]`,
  **V11** `[REL-OBSERVATION]`, **V12** `[REL-ENDPOINT]` (advisory).
- Run order, per feature-003's Feature Flow steps 1–8:
  1. Argument parsing via the `while [[ $# -gt 0 ]]; do case "$1" in … esac done` loop with
     `shift 2` per flag (`--file`, `--external-sources`); unknown flag -> stderr + exit 2.
  2. Load the schema and the vocabulary; either missing or malformed -> **exit 2 before any check
     runs**, so a configuration error is never reported as an artifact defect.
  3. Read the frontmatter block once with the awk extractor pattern `lint-frontmatter.sh` /
     `kb-freshness-check.sh` share; run **V9**.
  4. Locate the single table; assert the header and delimiter rows are byte-equal to D1's forms; run
     **V1** per data row. A V1 failure is fatal for that row only — it is reported and excluded from
     V2–V8, V11 and V12, and the run continues.
  5. Per well-shaped row: **V2** (parse + resolve both ids), **V3**, **V4**, **V6**, **V7**, **V8**,
     **V11**, **V12**.
  6. Accumulate `rel_row_key` per row; a repeated key is **V5**.
  7. Assert the actual row order equals D7's sort order and that class 0 is a contiguous prefix —
     **V10**.
  8. Print findings and the trailer.
- Output: every finding as `[TAG] <doc>: <message>` on stdout, then a
  `Checked: N rows | Findings: M` trailer, mirroring `lint-frontmatter.sh`'s shape. stderr carries
  diagnostics only. **No file is written.** The validator emits **rubric tags, not severities** — the
  same division of labour `lint-frontmatter.sh` uses with `[FM-MISSING]` / `[FM-INVALID]`; the
  skill's VALIDATE state and `grade-graph.sh` (task-029) map tags to severities.
- Exit scheme: `0` clean, `1` one or more findings, `2` usage / unreadable input / malformed schema
  or vocabulary — the linter semantics `coding-standards.md` records verbatim. No new code invented.
- `set -uo pipefail` (not `-euo`), following the read-only-linter precedent `kb-citation-lint.sh`,
  which intentionally tolerates non-zero from `grep`/`awk`.
- **V9 asserts `generator: build-relationships.sh`** — the script name, matching the
  `build-kb-index.sh` precedent and reconciled with feature-010 on 2026-07-28. Task-023 emits that
  value; this task checks it.
- **V11** reuses `kb-citation-lint.sh`'s own path pattern
  `[A-Za-z0-9_./-]+\.(md|sh|py|mjs|js|ts|yml|yaml|json|toml|txt|ps1)` for the durable-anchor
  predicate, and its bare-`file.ext:LINE` discrimination verbatim (a colon followed by digits is a
  violation unless the next character is a letter, a `-` plus a letter, or a `.` plus a digit).
- **Out of scope:** the library functions (tasks 014, 015); the rubric's check -> severity mapping
  and `grade-graph.sh` (task-029); the one-negative-fixture-per-validator suite and the Q4 synthetic
  `external-sources.md` (task-035); the artifact this validates (task-023).
- **Size note.** This is the largest task in the breakdown, and it is written as tabled. If it
  overruns a single agent session it splits **at the vocabulary seam and nowhere else**:
  vocabulary-independent half — `V1`, `V2`, `V7`–`V11`, plus the argument parsing, the run driver
  and the `0`/`1`/`2` exit scheme; vocabulary-dependent half — `V3`–`V6` and `V12`. Do not split it
  by any other line.

**Acceptance Criteria:**

- [ ] `canonical/aid/scripts/graph/validate-relationships.sh` exists, sources
      `relationship-schema.sh`, and implements all twelve checks under exactly the tags above.
- [ ] Each check's failure mode matches feature-003's Validators table — the finding names the id,
      label, key, field, or row ordinal that table specifies for it.
- [ ] A V1 failure reports the row and excludes it from V2–V8, V11 and V12 while the run continues;
      no malformed row is guessed at.
- [ ] V4 accepts a symmetric relation's `S2T == T2S` row as **valid** on the strength of its entry's
      `symmetry: symmetric`, not merely because the two labels happen to match.
- [ ] V5 keys on the relation pair as well as the endpoints, so two genuinely different typed
      relations between the same two nodes both survive while a verbatim repeat and a separately
      written inverse row of the *same* relationship collapse to one key. Rows identical but for
      their `Observation` are flagged.
- [ ] V7 rejects any `int:` id carrying a `#<symbol>` narrowing — the table-side half of AC-16.
- [ ] V9 requires `kb-category`, `source`, `generator`, `objective`, `summary` and `tags` present and
      non-empty; `objective` and `summary` single-line and pipe-free; `generator` equal to
      `build-relationships.sh`; the block present as the first content in the file; and no timestamp
      in the table, in any row, or in the `AUTO-GENERATED` marker. `graph_inputs_digest`,
      `graph_generated_at`, `kb_gaps` and any other unknown key are tolerated and not validated.
- [ ] V10 asserts the D7 `LC_ALL=C` order over `(class, source_id, target_id, s2t, t2s, provenance)`
      and that class 0 is a contiguous prefix, naming the first out-of-order ordinal on failure.
- [ ] V12 is emitted as an advisory `[REL-ENDPOINT]` finding at `[LOW]`, names the relation, the
      observed prefix pair and the pair set the vocabulary lists, and appears in **no**
      `grade-graph.sh` rubric row (feature-010 D4 has no V12 entry) — so it cannot gate.
- [ ] Every finding is printed as `[TAG] <doc>: <message>` on stdout and the run ends with a
      `Checked: N rows | Findings: M` trailer; stderr carries diagnostics only; the script writes no
      file.
- [ ] Exit codes are exactly `0` clean / `1` findings / `2` usage, unreadable input, or malformed
      schema or vocabulary; a missing or malformed schema or vocabulary exits 2 **before the first
      check runs**.
- [ ] The script uses `set -uo pipefail`, has a Purpose / Usage / Exit-codes header, and `-h|--help`
      re-prints a slice of it.
- [ ] No relation label, no column name, no provenance value and no id prefix is hard-coded in the
      script — all come from `rel_load_schema` and `rel_load_vocabulary`.
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden** — the vehicle is `tests/canonical/test-*.sh`, which the one-type rule
      forces into a separate TEST task; the named suite lands in **task-035**, carrying one negative
      fixture per V1–V12 plus a clean pass and the Q4 synthetic `external-sources.md`.
- [ ] Only `canonical/` is edited; nothing under `profiles/` or `.claude/` is hand-edited (the FULL
      render is task-044).
- [ ] The code baseline holds (`.aid/knowledge/coding-standards.md`) and the delivery gate's
      `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.
