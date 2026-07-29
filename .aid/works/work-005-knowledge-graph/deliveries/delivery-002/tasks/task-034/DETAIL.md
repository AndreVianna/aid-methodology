# task-034: `test-relationship-schema.sh` library and loader-rejection suite

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

**Depends on:** task-015

**Scope:**

- Create `tests/canonical/test-relationship-schema.sh`, the suite feature-003's Layers table
  names for the D9 library: "id grammars, slug rule, normalisation, row key, sort key, and
  `rel_load_vocabulary`".
- Cover every function of the D9 surface exposed by
  `canonical/aid/scripts/graph/relationship-schema.sh`:
  - **`rel_load_schema`** -- populates the column list, required set, provenance enum and prefix
    set from D1's YAML.
  - **`rel_parse_id`** -- splits `<prefix>`/`<body>`/`<anchor-or-symbol>` and returns non-zero on
    a grammar violation. Assert the three grammars of D2: a `kb:` doc plus optional
    `#<anchor>`; an `int:` repo-relative path, `/`-separated, exact on-disk case, with the
    trailing-`/` directory form accepted; an `ext:` key matching
    `[A-Za-z0-9][A-Za-z0-9._-]*`. Assert the rejections: a leading `./`, a `\`, a `..` segment, a
    drive letter, a leading `/`, whitespace in an `ext:` key, and a `://` scheme in an `ext:`
    key -- each rejected **before any I/O**, per the path-confinement rule
    `coding-standards.md` records for `connector-secret.sh`.
  - **The slug rule (D2a).** Assert all four steps -- strip leading `#`s and surrounding
    whitespace, lowercase, delete every character outside `[a-z0-9 -]`, replace each remaining
    space with `-`. Use the two on-disk confirmations as fixtures: `## JavaScript / Node
    Conventions` -> `javascript--node-conventions` and `## Performance & Health` ->
    `performance--health` (the deleted character leaves two spaces, hence two hyphens). Assert
    the slug is recomputed from the doc's ATX headings and that the hand-maintained `##
    Contents` list is **never** parsed.
  - **`rel_resolve_id`** -- prints `ok` or a reason token, per D2.
  - **`rel_display_name`** (D5) -- `kb:<doc>` -> `<doc>`; `kb:<doc>#<anchor>` ->
    `<doc> § <heading-text>` with the heading text verbatim; `int:<path>` and `int:<path>/`
    verbatim including the trailing slash; `ext:<key>` -> `<key>`. Assert it is a pure function
    of the id -- no per-row authoring, no basename shortening.
  - **`rel_normalise_row`** (D7) -- swaps the two ids, the two names and `S2T`/`T2S` when
    `Source Id > Target Id` under `LC_ALL=C` byte ordering; leaves a self-edge
    (`Source Id == Target Id`) as written; and is information-preserving.
  - **`rel_row_key`** (D7) -- `source_id \x1f target_id \x1f s2t \x1f t2s` over the **normalised**
    row. Assert a verbatim repeat and a separately written inverse row collapse to the same key,
    and that a symmetric relation's `(A,B)` and `(B,A)` rows collapse to one key.
  - **`rel_sort_key`** (D7) -- the `LC_ALL=C` tuple `(class, source_id, target_id, s2t, t2s,
    provenance)` with `class` `0` for `declared`/`derived` and `1` for `inferred`; assert class 0
    sorts as a contiguous prefix.
- Cover **`rel_load_vocabulary`** (D4) against a **fixture** vocabulary, never against
  feature-001's real file: one well-formed seven-key fixture that loads cleanly, and **one
  fixture per rejection class, each asserted to exit 2** -- missing key, unknown key, duplicate
  key, empty value, keys out of order, enum violation (`symmetry` outside
  `asymmetric`/`symmetric`; a `passes` value outside `declared`/`derived`/`inferred`; an
  `endpoint_kinds` token whose prefix is outside `kb:`/`int:`/`ext:`), undeclared `category`,
  broken closure, broken involution, `symmetry`/`inverse` disagreement, absent file, and empty
  `pairs:`. Each rejection message must name the resolved absolute path of the file, the entry's
  `relation` (or its ordinal when `relation` is what is missing), and the offending key.
- Assert the restricted-YAML subset is **enforced, not assumed**: anchors, aliases, merge keys,
  multi-line block scalars (`|`, `>`), a second document (`---`), nesting below an entry's scalar
  and flow values, and a multi-line `endpoint_kinds` or `passes` each exit 2.
- Assert the **two-top-level-key** parse contract holds: `pairs:` and `categories:` only. The
  `coverage_bearing` reviewable subset lives in a **sibling file** beside the vocabulary
  (delivery-003, task-045) and `rel_load_vocabulary` must **not** be asked to tolerate a third
  top-level key -- a fixture carrying one exits 2.
- Assert **entry order is not enforced**: a vocabulary whose `pairs:` are not sorted by
  `category` then `relation` still loads, since membership and pairing are order-free.
- Assert **no relation label appears anywhere in the `graph/` script tree** -- the greppable proof
  that the loader/content split is real rather than nominal (feature-003 D4).
- Out of scope: the twelve validators V1-V12 and the synthetic `external-sources.md` fixture
  (**task-035**); the library and loader implementations themselves (tasks 014, 015);
  feature-001's real vocabulary file (task-002).
- Discovered by the `tests/canonical/test-*.sh` glob with **no edit to `tests/run-all.sh`**;
  sources `tests/lib/assert.sh`; uses the `ID + description` label convention of
  `tests/canonical/test-guardrails-d012.sh`; builds every fixture under `mktemp -d` (A-6).

**Acceptance Criteria:**

- [ ] `tests/canonical/test-relationship-schema.sh` exists, sources `tests/lib/assert.sh`, uses
      the `ID + description` label convention, and is discovered by the glob with no edit to
      `tests/run-all.sh`.
- [ ] Every function of D9 -- `rel_load_schema`, `rel_load_vocabulary`, `rel_parse_id`,
      `rel_resolve_id`, `rel_display_name`, `rel_normalise_row`, `rel_row_key`, `rel_sort_key` --
      has at least one passing and one failing case asserted.
- [ ] All three id grammars are asserted, including the `int:` trailing-slash directory form and
      the `int:<path>#<symbol>` narrowing that the grammar admits (V7's rejection of it in an
      emitted table is task-035's, not this suite's).
- [ ] Every D2b rejection -- leading `./`, `\`, `..`, drive letter, leading `/` -- and every D2c
      rejection -- whitespace, `/`, `\`, `..`, `://` -- is asserted, and rejection happens before
      any filesystem access.
- [ ] The slug rule is asserted with the two on-disk confirmations
      (`javascript--node-conventions`, `performance--health`) and the suite asserts the `##
      Contents` list is not consulted.
- [ ] `rel_display_name` is asserted for all four id forms of D5, including the `§` heading form
      and the verbatim `int:` path.
- [ ] `rel_normalise_row` is asserted to swap under `LC_ALL=C` byte ordering, to leave self-edges
      untouched, and to be information-preserving.
- [ ] `rel_row_key` is asserted to collapse a verbatim repeat, a separately written inverse row,
      and a symmetric relation's two orientations to a single key.
- [ ] `rel_sort_key` is asserted to place class 0 as a contiguous prefix under `LC_ALL=C`.
- [ ] There is exactly one fixture per `rel_load_vocabulary` rejection class named in
      feature-003's Layers table, each asserted to exit 2 with a message naming the resolved
      absolute path, the entry `relation` or ordinal, and the offending key.
- [ ] The restricted-YAML subset violations (anchors, aliases, merge keys, block scalars, a
      second document, nesting, multi-line flow sequences) each exit 2.
- [ ] A fixture vocabulary carrying a third top-level key exits 2 -- the loader is not widened
      for `coverage_bearing`.
- [ ] An unsorted but well-formed `pairs:` block loads cleanly.
- [ ] A grep over `canonical/aid/scripts/graph/` finds no relation label.
- [ ] No fixture is feature-001's real `relation-vocabulary.yml`, and no fixture reads any path
      under `.aid/works/` (A-6).
- [ ] **Tests are deterministic** -- no wall-clock dependence, no network, no ordering
      dependence; `LC_ALL=C` on every sort; repeated runs agree.
- [ ] **Clean setup/teardown** -- every fixture is created under `mktemp -d` and removed on exit
      including on failure (`trap`); `git status --porcelain` is clean afterwards.
- [ ] **Every acceptance criterion from feature-003 that this suite carries is covered**: AC-1's
      id-resolution grammar half, AC-2's membership and pairing loader half, and AC-3's
      duplicate-collapse key half.
- [ ] The suite passes under `HOME="$(mktemp -d)" bash tests/run-all.sh`, and no existing suite
      regresses.
