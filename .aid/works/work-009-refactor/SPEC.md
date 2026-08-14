#### D-6. What is *not* in the data model

Restating the boundary so no downstream task widens it: the discovery-area ledger
`.aid/knowledge/STATE.md` stays markdown and stays a KB document (out of scope, three
independent reasons in `REQUIREMENTS.md §4`); `.aid/.temp/HOUSEKEEP_STATE_*.md` and the
control-signal/heartbeat files are untouched; `REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`,
`BLUEPRINT.md` and `DETAIL.md` stay markdown and stay reviewable; no JSON Schema artifact and
no CI schema-validation gate is added (A-5); and no rollup is ever persisted into a parent
file (C-8).

### Feature Flow

**Unchanged -- behavior-preserving refactor.** There is no request/response path here: AID's
state layer is local files with one writer and several readers, and the *sequence* of
operations is identical before and after. Recorded explicitly, because "the flow is unchanged"
is itself an acceptance property (SP-4, SP-6, SP-10), not an absence of content:

- **Write flow (unchanged in every step):** resolve target file (env override -> layout
  auto-detect -> path resolution) -> validate field name and closed enum -> acquire the
  sentinel lock (`set -o noclobber` atomic create, 0.5 s sleep-poll, `AID_LOCK_TIMEOUT`
  retries, exit 2 on contention, `writeback-state.sh:506-526`) -> compute new bytes to a temp
  file -> verify (non-empty **and** target key present) -> atomic `mv` -> release lock via the
  `EXIT` trap. Every `die` path still leaves the original file untouched. What changes is only
  the "compute new bytes" step's internals.
- **Read flow (unchanged):** enumerate worktree roots -> enumerate work dirs -> **one** read
  per work state file -> parse -> build the model -> derive the read-time unions -> reconcile
  most-advanced-wins across branches. Still one read (`reader.py` step 5a, reused by
  `read_repo_detail` for `raw_state`, `reader.py:696-713`), still bounded
  (`io_bounds.py`, `MAX_READ_BYTES`), still `parse_warning`-not-throw.
- **Reviewer flow (one step removed):** derive `{{ARTIFACTS}}` from disk -> **filter out state