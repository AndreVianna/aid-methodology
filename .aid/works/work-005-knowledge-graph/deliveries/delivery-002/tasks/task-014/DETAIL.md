# task-014: `relationship-schema.yml` and the id/name/row primitives

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

**Depends on:** --

**Scope:**

- Create `canonical/aid/templates/graph/relationship-schema.yml`, the machine-readable form of
  feature-003 D1's column contract, with exactly five flat keys: `columns:` (the eight names in fixed
  order), `required:` (seven), `optional:` (`Observation`), `provenance:`
  (`declared`/`derived`/`inferred`), `prefixes:` (`kb`/`int`/`ext`). No script may hard-code the
  column list, the enum, or the prefix set — all three are read from this file, so adding a column is
  a one-file change plus a validator-test update rather than a grep across the pipeline.
- Create `canonical/aid/scripts/graph/relationship-schema.sh`: sourceable, side-effect-free on
  import, with a `Provides:` header index in the style of `lib/aid-install-core.sh`. Implement seven
  of feature-003 D9's eight functions:
  - `rel_load_schema <file>` — populate the column list, required set, provenance enum and prefix
    set from the YAML above.
  - `rel_parse_id <id>` — split `<prefix>` / `<body>` / `<anchor-or-symbol>` per D2; non-zero on a
    grammar violation. Per D2b, reject `..`, `\`, a leading `/`, a leading `./`, and a drive letter
    **before any I/O**, following the path-confinement precedent `coding-standards.md` records for
    `connector-secret.sh`.
  - `rel_resolve_id <id>` — resolve per D2 and print `ok` or a reason token: `kb:` against D2a's
    membership predicate (`find .aid/knowledge -maxdepth 1 -type f -name '*.md' ! -name '.*'`,
    consumed as a **set**) plus a recomputed ATX heading slug; `int:` by `test -f` / `test -d` from
    the root resolved once via `git rev-parse --show-toplevel`; `ext:` against D2c's `## Sources`
    table predicate (a row whose first cell is a backticked key).
  - `rel_display_name <id>` — D5's pure function over all four id forms.
  - `rel_normalise_row <8 fields>` — D7's orientation swap: when `Source Id > Target Id` under
    `LC_ALL=C`, swap the two ids, the two names, and `S2T Relation` with `T2S Relation`; self-edges
    are left as written.
  - `rel_row_key <8 fields>` — D7's `\x1f`-joined key over the **normalised** row.
  - `rel_sort_key <8 fields>` — D7's `(class, source_id, target_id, s2t, t2s, provenance)` tuple,
    `class` = `0` for `declared`/`derived` and `1` for `inferred`.
- The `kb:` slug rule is D2a's four steps: strip leading `#`s and surrounding whitespace, lowercase,
  delete every character outside `[a-z0-9 -]`, replace each remaining space with `-`. The resolver
  recomputes slugs from the doc's ATX headings and **never** reads its hand-maintained `## Contents`
  list, which is not authoritative.
- **Out of scope: `rel_load_vocabulary`.** Task-015 adds it to this same file, and the
  `relationship-schema.sh` serialisation is 014 -> 015 — this task must leave a clean surface for it
  and task-015 must not disturb this task's contents.
- **Out of scope:** `validate-relationships.sh` (task-016); the vocabulary file itself (task-002,
  delivery-001); the library's suite (task-034).
- Conventions: `set -eu` for the library, as feature-003 specifies following `build-kb-index.sh`;
  kebab-case filename; `snake_case` functions under the `rel_` prefix; `UPPER_SNAKE` globals; every
  sort and comparison `LC_ALL=C`; file errors print the resolved absolute path; no new exit code.

**Acceptance Criteria:**

- [ ] `canonical/aid/templates/graph/relationship-schema.yml` exists with exactly D1's five keys and
      the eight column names in D1's fixed order.
- [ ] Sourcing `canonical/aid/scripts/graph/relationship-schema.sh` produces no output, writes no
      file, and calls no `exit` — it is side-effect-free on import — and the file opens with a
      Purpose / Usage / Exit-codes header block plus a `Provides:` index.
- [ ] All seven functions exist with D9's contracts, and no column name, provenance value, or id
      prefix is hard-coded anywhere in the library: all four sets arrive through `rel_load_schema`.
- [ ] `rel_parse_id` rejects `..`, `\`, a leading `/`, a leading `./`, and a drive letter **before
      any filesystem call** — demonstrable by reading the function, since the rejection precedes
      every `test`.
- [ ] `rel_resolve_id`'s `kb:` branch recomputes heading slugs by D2a's four-step rule and reproduces
      the two on-disk confirmations: `## JavaScript / Node Conventions` ->
      `javascript--node-conventions` and `## Performance & Health` -> `performance--health`. It never
      parses a doc's `## Contents` list.
- [ ] `rel_resolve_id`'s `int:` branch resolves both the file form and the trailing-slash directory
      form from the repo root, and its `ext:` branch registers a key only from a `## Sources` table
      row whose first cell is a backticked key matching `[A-Za-z0-9][A-Za-z0-9._-]*`.
- [ ] `rel_display_name` matches D5 for all four forms, including `kb:<doc>#<anchor>` ->
      `<doc> § <heading-text>` with the heading text verbatim, and `int:` keeping the full
      repo-relative path (a basename is not unique in this repository).
- [ ] `rel_normalise_row` swaps ids, names and both relation labels together, leaves a self-edge
      untouched, and therefore makes `rel_row_key` collapse a verbatim repeat **and** a separately
      written inverse row to a single key.
- [ ] `rel_sort_key` emits the six-element tuple with `class` first, which is what makes class 0 a
      contiguous prefix once the rows are `LC_ALL=C`-sorted.
- [ ] The library defines **no** `rel_load_vocabulary` (task-015 adds it) and contains **no relation
      label** — a grep of `canonical/aid/scripts/graph/` finds no vocabulary member, which is
      feature-003 D4's stated proof that the 001/003 ownership split is real rather than nominal.
- [ ] All existing canonical suites still pass. IMPLEMENT's "unit tests for all new public methods"
      default is **overridden** — there is no unit-test vehicle for a shell library outside
      `tests/canonical/test-*.sh`, which the one-type rule forces into a separate TEST task; the named
      suite for this library lands in **task-034** (`tests/canonical/test-relationship-schema.sh`).
- [ ] Only files under `canonical/` are created; nothing under `profiles/` or `.claude/` is
      hand-edited (the FULL render is task-044).
- [ ] The code baseline holds — `.aid/knowledge/coding-standards.md` (shebang, header block,
      `set -eu` for the sourceable library, stdout for results and stderr for diagnostics,
      `LC_ALL=C`, resolved absolute paths in file errors, no invented exit code) — and the delivery
      gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this repository's resolved
      `review.minimum_grade` of **A+** (`.aid/knowledge/quality-gates.md`) — zero findings with
      Status `Pending` or `Recurred`. REQUIREMENTS.md §6 is not a code baseline; it holds only the six
      accessibility NFRs.
