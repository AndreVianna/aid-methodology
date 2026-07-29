# task-023: `build-relationships.sh` class-0 merge, ordering and artifact render

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

**Depends on:** task-014, task-016, task-021, task-022

**Scope:**

- Create `canonical/aid/scripts/graph/build-relationships.sh` and implement feature-005's Feature
  Flow **steps 7, 11 and 12**.
- **Step 7 — merge and freeze class 0.** Normalise every class-0 row with `rel_normalise_row`, key
  it with `rel_row_key`, and de-duplicate on a **total** rule: a repeated key keeps the row with the
  stronger provenance (`declared` over `derived`) and, on a tie, the lexicographically smaller
  `observation`. Because the rule is total, the survivor never depends on arrival order. Sort with
  `LC_ALL=C` over `(class, source_id, target_id, s2t, t2s, provenance)` (feature-003 D7). Write the
  frozen block to `.aid/.temp/graph/rows-class0.tsv` and record its key set for pass 2 to test
  against.
- **Step 11 — render and write `.aid/knowledge/relationships.md`** (allowlist W1):
  - feature-003 D8's frontmatter as the **first bytes** of the file — no BOM, no leading blank line —
    carrying `kb-category: primary`, `source: generated`,
    **`generator: build-relationships.sh`**, single-line pipe-free `objective:` and `summary:`,
    `sources:`, `tags:` including the concern id `C2`, `see_also:`, `owner:`, `audience:`, and
    `contracts:`;
  - then the `<!-- AUTO-GENERATED ... -->` marker carrying the generator path and the regenerate
    command **and no timestamp**;
  - then the `# Relationships` title;
  - then exactly one GFM pipe table, eight columns in D1's fixed order, class-0 rows as a contiguous
    prefix.
- `generator:` is the **script name**, not the skill name — the `build-kb-index.sh` precedent that
  `frontmatter-schema.md` specifies, reconciled with feature-010 on 2026-07-28. Task-016's `V9` is
  the check that asserts it.
- No `changelog:` field, and no timestamp in the table, in any row, or in the `AUTO-GENERATED`
  comment — the deliberate divergence from `INDEX.md`, which embeds `$TS` and therefore churns on
  every run.
- Byte-level row grammar (D1): header and delimiter rows byte-equal to D1's forms; every data row a
  leading `|`, each cell surrounded by exactly one space, a trailing `|`; an empty `Observation`
  renders as a single space; a literal pipe escaped as `\|` reusing `build-kb-index.sh`'s `esc()`
  rule; **LF-only line endings including the last line**, which matters because the repository is
  authored on Windows.
- **Step 12 — self-validate.** Invoke `validate-relationships.sh` (task-016) on the file just
  written. A non-zero exit is reported and surfaces as ledger findings, and **the artifact is still
  written**, so the failure is visible rather than hidden behind a missing file.
- Exit codes: `0` success, `1` a write failure or a validator finding, `2` usage error or a
  missing/malformed vocabulary, edge-relation map, or feature-004 stream.
- **Out of scope:** the bounded pass-2 residue, the four merge-enforced bounds, and the class-1
  merge — task-024 adds steps 8–10 to this same file and must not disturb this task's contents (the
  `build-relationships.sh` serialisation is 023 -> 024). This task emits an empty class-1 block.
- **Out of scope:** the pass-2 dispatch prose (task-025); the byte-identity suite (task-038); the
  agent-pass bound suite (task-039); feature-010's `graph_inputs_digest` / `graph_generated_at`
  values, which that feature supplies and which sit outside the byte-identity boundary by design.
- Conventions: `set -euo pipefail`; the `while … case … shift 2` argument loop, unknown flag ->
  stderr + exit 2; a one-line `[relationships] …` stderr summary; any value read from frontmatter or
  a template treated as untrusted when passed to git (`--end-of-options` guards a commit-ish, as
  `kb-freshness-check.sh` does).

**Acceptance Criteria:**

- [ ] `canonical/aid/scripts/graph/build-relationships.sh` exists with `#!/usr/bin/env bash`,
      `set -euo pipefail`, a Purpose / Usage / Exit-codes header, `-h|--help`, and a
      `[relationships] …` one-line stderr summary.
- [ ] Class-0 de-duplication uses a total order — stronger provenance wins, lexicographically smaller
      `observation` breaks the tie — so the surviving row is independent of arrival order, provable
      by feeding the same rows in two different orders and getting the same output.
- [ ] The sort is `LC_ALL=C` over D7's six-element tuple with `class` leading, and class 0 is a
      contiguous prefix of the emitted table.
- [ ] `.aid/knowledge/relationships.md` opens with D8's frontmatter as its first bytes — no BOM, no
      leading blank line — with every field D8 lists present and `generator: build-relationships.sh`.
- [ ] There is no `changelog:` field and **no timestamp** in the table, in any row, or in the
      `AUTO-GENERATED` marker.
- [ ] The header and delimiter rows are byte-equal to D1's forms; every data row has eight cells with
      single-space padding; an empty `Observation` renders as `| |`; a literal pipe is escaped `\|`;
      the file is LF-only including its last line.
- [ ] The file carries exactly one GFM pipe table, and its body contains no column-0 `---` line.
- [ ] `validate-relationships.sh` is invoked on the file just written; a non-zero exit is reported
      and the artifact is still written.
- [ ] Running the script twice over an unchanged fixture repository yields a **byte-identical class-0
      block** — the AC-5 property `tests/canonical/test-relationships-reproducible.sh` (task-038)
      then asserts as a suite.
- [ ] Exit codes are exactly `0` / `1` / `2` with feature-005's stated meanings; no new code is
      invented.
- [ ] The only files written are `.aid/knowledge/relationships.md` and paths under
      `.aid/.temp/graph/` — allowlist entries W1 and W5. No other Knowledge Base file is touched
      (FR-10 / AC-13), and in particular the script never invokes `build-kb-index.sh`.
- [ ] No relation label appears in the script.
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden** — the vehicle is `tests/canonical/test-*.sh`, which the one-type rule
      forces into a separate TEST task; the named suite lands in **task-038**.
- [ ] Only `canonical/` is edited; nothing under `profiles/` or `.claude/` is hand-edited (the FULL
      render is task-044).
- [ ] The code baseline holds (`.aid/knowledge/coding-standards.md`) and the delivery gate's
      `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.
