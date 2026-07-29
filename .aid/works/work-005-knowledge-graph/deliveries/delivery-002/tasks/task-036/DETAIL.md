# task-036: `test-harvest-declared.sh` declared-carrier suite

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

**Depends on:** task-021

**Scope:**

- Create `tests/canonical/test-harvest-declared.sh`: "one fixture per D4 carrier, plus the
  `relationships.md`/`INDEX.md` source-exclusion assertions" (feature-005 Layers table).
- **One fixture per declared-edge carrier of feature-005 D4**, each asserted to produce exactly
  the row shape D4's "Row" column states, stamped `provenance = declared`, `class = 0`, with the
  `observation` cell set to the matched carrier anchor:
  - `frontmatter-see-also` -- a `see_also:` list entry; row `kb:<doc>` -> `kb:<entry>`.
  - `frontmatter-sources-path` -- a `sources:` entry that is a repo-relative path or a glob; row
    `kb:<doc>` -> `int:<resolved node>`. Assert glob expansion against `nodes.tsv`: each match
    becomes an edge, and a glob matching nothing becomes a candidate.
  - `frontmatter-sources-url` -- a `sources:` entry matching the URL shape
    `^[a-z][a-z0-9+.-]*://`, using the same detector `kb-freshness-check.sh`'s `is_url` uses; row
    `kb:<doc>` -> `ext:<key>` **only if** the URL resolves to a registered key, and a candidate
    otherwise.
  - `inline-doc-link` -- both forms this KB uses: `[x.md](x.md)` and `[x.md](../knowledge/x.md)`;
    row `kb:<doc>` -> `kb:<target doc>`.
  - `inline-durable-anchor` -- a path-or-basename citation matched with **the exact character
    class and extension set `kb-citation-lint.sh` already uses**,
    `[A-Za-z0-9_./-]+\.(md|sh|py|mjs|js|ts|yml|yaml|json|toml|txt|ps1)`; row `kb:<doc>` ->
    `int:<resolved node>`.
  - `evidence-citation` -- a line whose **first token** is `Evidence:`; row `kb:<doc>` -> `int:`
    or `ext:`. Assert the negative that makes this carrier honest on this project: a prose label
    reading `Evidence: ...` *inside* a table cell or bullet is **not** a first-token match and
    produces no row -- the two occurrences in this repository's `coding-standards.md` are exactly
    that shape.
- **Not-an-edge assertions.** A frontmatter `contracts:` entry produces no row (its entries are
  structural cardinality assertions, not references to a node), and neither do `tags:`,
  `audience:`, `owner:`, or `changelog:`.
- **The two source-exclusion assertions.** `relationships.md` and `INDEX.md` are excluded **as
  sources of edges** while remaining valid **targets**:
  - A fixture `relationships.md` carrying a `see_also:` entry and an inline doc link produces
    **zero** outbound rows -- self-exclusion is mandatory, because harvesting the artifact being
    written would make the output depend on the previous run's output and FR-32 would become
    unprovable.
  - A fixture `INDEX.md` produces **zero** outbound rows -- harvesting its links would
    manufacture a `kb:INDEX.md -> kb:<doc>` edge for every document and duplicate every
    `see_also:` edge already harvested from the source doc.
  - A hand-authored fixture doc citing `INDEX.md` **does** produce a real edge targeting it, and
    likewise for `relationships.md`.
- **The `kb:` node set (D2).** Assert `.aid/.temp/graph/kb-nodes.tsv` carries
  `kb_id | name | doc | anchor`, one row per KB document and one per ATX heading within it, with
  `kb_id` per feature-003 D2a and `name` per feature-003 D5; the document scan set is the
  membership predicate `find <kb> -maxdepth 1 -type f -name '*.md' ! -name '.*'`; and the output
  is `LC_ALL=C`-sorted with LF endings.
- **Resolution never guesses.** A basename resolving to exactly one surviving node becomes an
  edge; one resolving to more than one becomes a candidate with `drop_reason`
  `ambiguous-basename`; one resolving to zero becomes `unresolved-reference`. Assert all three.
- Fixtures are a self-built miniature KB plus a fixture vocabulary and edge-relation map, created
  under `mktemp -d`, depending on no work folder's contents (A-6). The vocabulary is a **fixture**,
  not feature-001's real file, so this suite runs while feature-001 is still open (D-1).
- Out of scope: the observation-typing and map-gate suite (**task-037**), the reproducibility
  suite (**task-038**), the pass-2 bound suite (**task-039**), and `harvest-declared.sh` itself
  (task-021).
- Discovered by the `tests/canonical/test-*.sh` glob with **no edit to `tests/run-all.sh`**;
  sources `tests/lib/assert.sh`; uses the `ID + description` label convention of
  `tests/canonical/test-guardrails-d012.sh`.

**Acceptance Criteria:**

- [ ] `tests/canonical/test-harvest-declared.sh` exists, sources `tests/lib/assert.sh`, uses the
      `ID + description` label convention, and is discovered by the glob with no edit to
      `tests/run-all.sh`.
- [ ] All six D4 carriers have a fixture, and each asserts the exact endpoint prefix pair D4's
      "Row" column states, `provenance = declared`, `class = 0`, and an `observation` equal to
      the matched carrier anchor.
- [ ] `frontmatter-sources-path` asserts both glob expansion to one edge per match and the
      matching-nothing case becoming a candidate.
- [ ] `frontmatter-sources-url` uses `kb-freshness-check.sh`'s `is_url` URL shape and asserts
      both the registered-key edge and the unregistered-key candidate.
- [ ] `inline-doc-link` asserts both `[x.md](x.md)` and `[x.md](../knowledge/x.md)`.
- [ ] `inline-durable-anchor` uses `kb-citation-lint.sh`'s exact character class and extension
      set.
- [ ] `evidence-citation` asserts a first-token match produces a row and an in-prose
      `Evidence:` label does not.
- [ ] `contracts:`, `tags:`, `audience:`, `owner:` and `changelog:` are each asserted to produce
      no row.
- [ ] A fixture `relationships.md` and a fixture `INDEX.md` each produce zero outbound rows,
      while a doc citing either produces a real inbound edge.
- [ ] `kb-nodes.tsv` is asserted for its four fields, its one-row-per-doc plus one-row-per-ATX-
      heading population, its `LC_ALL=C` order, and its LF endings.
- [ ] All three resolution outcomes are asserted: unique-basename edge, `ambiguous-basename`
      candidate, `unresolved-reference` candidate.
- [ ] The suite uses a fixture vocabulary and a fixture edge-relation map, never feature-001's
      real `relation-vocabulary.yml`.
- [ ] No fixture reads any path under `.aid/works/` (A-6).
- [ ] **Tests are deterministic** -- no wall-clock dependence, no network, no ordering
      dependence; `LC_ALL=C` on every sort; repeated runs agree.
- [ ] **Clean setup/teardown** -- every fixture is created under `mktemp -d` and removed on exit
      including on failure (`trap`); `git status --porcelain` is clean afterwards.
- [ ] **Every acceptance criterion from feature-005 that this suite carries is covered**: the
      declared half of AC-4's provenance population, FR-30's carrier set, and the D2
      source-exclusion rule that AC-5 depends on.
- [ ] The suite passes under `HOME="$(mktemp -d)" bash tests/run-all.sh`, and no existing suite
      regresses.
