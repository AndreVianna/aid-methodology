# task-059: `graph-model.js` table parser and `GraphModel` construction

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-014

**Scope:**
- Create `canonical/aid/templates/knowledge-graph/graph-model.js` and author its **first slice
  only**: `parseRelationships(markdownText)` and the `GraphModel` it returns.
- Implement the loader: skip the first `---` ... `---` frontmatter block, locate the single
  eight-column table, and read the `sourceStamp` and `recordedGaps` values out of that
  frontmatter (`kb_gaps` is stored raw here; its verification is task-061).
- Implement the records: `Node` = `{id, name, kind, glyph, kbDoc, degree, kbDegree, intDegree,
  extDegree}` and `Edge` = `{key, sourceId, targetId, s2t, t2s, category, provenance, observation,
  row}`, plus `nodes`, `edges`, `rowCount`, `categoryOf`, `nameConflicts`.
- Author the frozen build-time constant `RELATION_CATEGORY` from feature-001's closed vocabulary
  at `canonical/aid/templates/graph/relation-vocabulary.yml`, and the column contract from
  feature-003's `relationship-schema.yml` (task-014) so the parser and the emitter agree on the
  eight column names and the id grammar.
- **Out of scope:** `LensState`, `project()`, `PRESETS`, `INITIAL_LENS` (task-060); `createStore`,
  the `kb_gaps` verification and zero-row materialisation (task-061); `coverageBearing`, which is
  read from the shared predicate module, never parsed from the page; any `import` statement.

**Acceptance Criteria:**
- [ ] `parseRelationships` skips exactly the **first** leading `---` ... `---` block and resumes
      scanning after it; a later `---` in the body is treated as a thematic break, matching the
      first-block-only scoping `build-kb-index.sh`'s `extract_field` uses (Q3).
- [ ] Exactly the eight §5.2 columns are parsed -- Source Id, Source Name, Target Id, Target Name,
      S2T Relation, T2S Relation, Provenance, Observation -- and their names and order match
      `relationship-schema.yml`'s D1 contract; a row with a different column count throws.
- [ ] `Node.kind` is taken from the id prefix alone (`kb:` / `int:` / `ext:` per §5.3); a malformed
      prefix **throws** rather than producing a silent third category.
- [ ] `Node.glyph` is assigned in the model (not by a renderer) and carries `kind` without colour;
      `Node.kbDoc` is populated for `kind === 'kb'` only and is `null` otherwise.
- [ ] `Edge.key` is `sourceId`, `targetId` and `s2t` joined by `U+0000`, and is unique across the
      parsed table; `Edge.row` is the 1-based table row index.
- [ ] An `s2t` value absent from `RELATION_CATEGORY` throws -- there is no `'uncategorised'`
      bucket; an empty `Provenance` cell throws rather than defaulting.
- [ ] `RELATION_CATEGORY` is frozen, authored from the closed vocabulary, and is **not** parsed
      from the page (AC-10); its key set is exactly the vocabulary's relation labels.
- [ ] `degree`, `kbDegree`, `intDegree` and `extDegree` are computed in one pass over `edges` and
      satisfy `degree === kbDegree + intDegree + extDegree` for every node.
- [ ] `nameConflicts` records `{id, kept, seen}` for every id whose display name differs between
      occurrences, and parsing does not throw on such an id.
- [ ] The file declares **no top-level `import`** and references shared exports directly from the
      module scope -- the constraint GV01 asserts, required because the whole inlined block is one
      module scope and a `file://` page cannot import a relative ES module.
- [ ] All existing canonical suites still pass, and no suite is modified by this task; the named
      suites are `tests/canonical/test-graph-view-shell.sh` (tasks 070/071) and the lens-parity
      suite (task-072). *(Stated override of the IMPLEMENT default "unit tests for all new public
      methods": the browser-side view files have no unit-test vehicle outside those
      `tests/canonical/test-*.sh` suites, which the one-type-per-task rule places in TEST tasks.)*
- [ ] Build passes: `python .claude/skills/generate-profile/scripts/run_generator.py` completes;
      the render-drift confirmation for this delivery is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
