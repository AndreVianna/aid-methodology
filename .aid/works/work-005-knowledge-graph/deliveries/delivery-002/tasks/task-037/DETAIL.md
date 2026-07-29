# task-037: `test-derive-edges.sh` observation-typing and map-gate suite

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

**Depends on:** task-022

**Scope:**

- Create `tests/canonical/test-derive-edges.sh`: "one fixture per observation kind; unmapped kind
  -> candidate, never an untyped row; and the three D3 map-load gates (unmapped kind,
  pass-illegal mapping, endpoint-illegal mapping) each exit 2" (feature-005 Layers table).
- **One fixture per observation kind** of feature-004 D5, each an `observations.tsv` row typed
  through the edge-relation map and asserted to emit a relationship row with
  `provenance = derived`, `class = 0`, and `observation` set to the observation's evidence anchor
  **verbatim**:
  - `path-reference` -- endpoint pairs `int:->int:` and `int:->kb:` are both legal (a source
    artifact citing `.aid/knowledge/<doc>.md` is a real coverage edge).
  - `invocation` -- `int:->int:` only.
  - `dependency` -- `int:->int:` and `int:->kb:`; assert the one `kb:`-crossing case, an
    `.aid/settings.yml` `knowledge.doc_set` entry naming a KB doc.
  - `include` -- `int:->int:` only; the `{{include:agent-boilerplate}}` directive shape.
  - `convention` -- `int:->int:` only; a rule-based structural edge.
- **`t2s` is looked up, never chosen.** Assert every emitted row's `t2s` equals the mapped
  relation's `inverse` as loaded from the fixture vocabulary, so a pair is internally consistent
  by construction -- which is why feature-003's `V4` should never fire on this writer's output
  and, because the endpoint gate already passed, its advisory `V12` should not fire either.
  Assert both by running `validate-relationships.sh` over the emitted rows and finding neither
  tag.
- **Unmapped kind -> candidate, never an untyped row.** An observation whose kind carries no
  mapping appends a `candidates.tsv` row and emits **nothing**. Assert that no emitted row ever
  carries a blank or invented relation label -- there must be no code path that produces one.
- **The three fail-closed map-load gates (D3), each exiting 2 before any row exists**, with a
  message naming the resolved absolute path:
  1. **Arity / unmapped kind** -- an entry that is not exactly four `|`-separated fields, and an
     entry whose relation label is empty or is not a vocabulary member. The message names the
     path and the offending entry or unmapped kind.
  2. **Pass legality** -- the entry's `<emitting-pass>` is absent from the mapped relation's
     `passes` list; e.g. a `derived` harvest routed to a relation the vocabulary marks
     `declared`-only.
  3. **Endpoint legality** -- a pair in the entry's `<endpoint-kinds>` is absent from the mapped
     relation's `endpoint_kinds`. The message names both sets.
  Assert for all three that the exit happens **at load, before any row is produced**, so a
  misconfiguration surfaces as a usage error rather than as a table full of mistyped rows.
- **The `edge-relation-map.yml` encoding contract.** Field 3 lists multiple endpoint pairs
  **comma-separated with no space**, because a plain YAML scalar containing colon-space would
  parse as a mapping. Assert that an entry written with a space after the comma, or with
  space-separated pairs, is rejected rather than silently mis-parsed; and assert the map is
  compared against the vocabulary **after parsing, never textually** -- the vocabulary
  double-quotes its `endpoint_kinds` tokens because they sit in flow context, and this file does
  not.
- **`derive-edges.sh` performs no traversal of its own.** Assert it reads only
  `.aid/.temp/graph/observations.tsv` and the two map/vocabulary files, so feature-004's
  single-scanner seam holds.
- One recorded no-op worth an assertion: a `dependency` observation over a
  `profiles/*/emission-manifest.jsonl` `src` -> `dst` pair yields **no row**, because every `dst`
  is inside an excluded render tree.
- Fixtures -- a fixture `observations.tsv`, a fixture vocabulary, and a fixture edge-relation
  map -- are built under `mktemp -d` and depend on no work folder's contents (A-6). The
  vocabulary is a fixture, never feature-001's real file.
- Out of scope: the declared-carrier suite (**task-036**), the reproducibility suite
  (**task-038**), the pass-2 bound suite (**task-039**), and `derive-edges.sh` and
  `edge-relation-map.yml` themselves (tasks 020, 022).
- Discovered by the `tests/canonical/test-*.sh` glob with **no edit to `tests/run-all.sh`**;
  sources `tests/lib/assert.sh`; uses the `ID + description` label convention of
  `tests/canonical/test-guardrails-d012.sh`.

**Acceptance Criteria:**

- [ ] `tests/canonical/test-derive-edges.sh` exists, sources `tests/lib/assert.sh`, uses the
      `ID + description` label convention, and is discovered by the glob with no edit to
      `tests/run-all.sh`.
- [ ] All five observation kinds -- `path-reference`, `invocation`, `dependency`, `include`,
      `convention` -- have a fixture, each asserting `provenance = derived`, `class = 0`, and an
      `observation` equal to the source observation's evidence anchor verbatim.
- [ ] The `int:->kb:` cases of `path-reference` and `dependency` are each asserted, including the
      `knowledge.doc_set` crossing.
- [ ] Every emitted row's `t2s` is asserted equal to the mapped relation's `inverse`; running
      `validate-relationships.sh` over the emitted rows produces neither a `[REL-PAIR]` nor a
      `[REL-ENDPOINT]` finding.
- [ ] An unmapped observation kind is asserted to append a `candidates.tsv` row and emit no
      relationship row; no emitted row anywhere carries a blank or invented relation label.
- [ ] Each of the three map-load gates is asserted to exit `2`, with a message naming the
      resolved absolute path plus (respectively) the offending entry / unmapped kind, the pass
      sets, and both endpoint sets.
- [ ] All three gates are asserted to fire **before** any row is written -- no partial output
      exists after a gate failure.
- [ ] An `<endpoint-kinds>` field written with a space after the comma or with space-separated
      pairs is asserted rejected, and the comparison against the vocabulary is asserted to happen
      after parsing rather than textually.
- [ ] `derive-edges.sh` is asserted to read only `observations.tsv`, the vocabulary, and the map
      -- it performs no `find` or `git ls-files`.
- [ ] A `profiles/*/emission-manifest.jsonl` `src` -> `dst` dependency observation is asserted to
      yield no row.
- [ ] The suite uses a fixture vocabulary and a fixture edge-relation map, never feature-001's
      real `relation-vocabulary.yml`.
- [ ] No fixture reads any path under `.aid/works/` (A-6).
- [ ] **Tests are deterministic** -- no wall-clock dependence, no network, no ordering
      dependence; `LC_ALL=C` on every sort; repeated runs agree.
- [ ] **Clean setup/teardown** -- every fixture is created under `mktemp -d` and removed on exit
      including on failure (`trap`); `git status --porcelain` is clean afterwards.
- [ ] **Every acceptance criterion from feature-005 that this suite carries is covered**: the
      `derived` half of AC-4's provenance population, AC-2's typed-from-the-vocabulary property
      for pass 1b, and the fail-closed configuration posture that FR-32 rests on.
- [ ] The suite passes under `HOME="$(mktemp -d)" bash tests/run-all.sh`, and no existing suite
      regresses.
