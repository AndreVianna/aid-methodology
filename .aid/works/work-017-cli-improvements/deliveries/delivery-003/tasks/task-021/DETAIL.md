# task-021: External-sources reader/model + external-source.add/remove ops

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.md.
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

**Type:** IMPLEMENT

**Source:** feature-010-external-sources-list -> delivery-003

**Depends on:** task-020, task-004 (delivery-001)

**Scope:**
- Add a thin wrapper parser `parse_external_sources(kb_dir)` (Python,
  `dashboard/reader/parsers.py`) / `parseExternalSources(kbDir)` (Node,
  `dashboard/server/reader.mjs`) as byte-parity twins -- NO new frontmatter parser. It calls the
  existing parity-tested `parse_doc_frontmatter(kb_dir / "external-sources.md")`
  (`parsers.py` line 513 / `reader.mjs` `parseDocFrontmatter` line 1073), takes its `sources_list`,
  drops the `(none)` placeholder, dedupes preserving order, and returns the list. An absent file ->
  `[]` (the parser already returns `[]` for a missing/frontmatter-less file).
- Add an additive field `external_sources: list[str]` on `RepoInfo` (`dashboard/reader/models.py`,
  beside `kb_state`, line 225): the deduped, order-preserved `sources:` entries with `(none)`
  filtered out; absent/empty registry -> `[]`. Surface it under `model.repo.external_sources` in
  the DM-1 envelope (the same object that carries `kb_state`); do NOT touch the DM-2 `/api/home`
  model. Wire the parser where `RepoInfo` is built: `reader.py` beside the
  `parse_kb_state(loc.kb_dir)` call (~line 402) and `reader.mjs` beside `parseKbState(loc.kbDir)`
  (~line 2619).
- Extend the DM-1 serializer twins (`server.py` `_ser_repo_info` line 595, `reader.mjs`
  `_buildRepoInfo` line 4327) with the `external_sources` key. Do NOT bump `schema_version`
  (additive key, `write_enabled` DM-A3/RC-2 no-bump precedent). Regenerate the twin golden fixtures
  (`test_server_py.py` / `test_server_node.mjs` DM-1 fixtures) in lockstep to keep DM-3 byte-parity.
- Reader-parity constraint (satisfied jointly with task-020's writer): `parse_doc_frontmatter`'s
  block-list continuation matches only contiguous `^[ \t]+-[ \t]*` item lines and does not strip a
  trailing inline `# comment`; the writer (task-020) normalizes the block to contiguous clean
  `  - <item>` lines directly under `sources:` so every dashboard-managed entry is reader-visible.
  This task must verify the wrapper surfaces exactly those normalized entries.
- Append TWO per-repo `OP_TABLE` rows (both `server.py` + `server.mjs` byte-parity twins),
  concretizing the `external-sources` placeholder feature-001 reserved: `external-source.add` ->
  `write-external-source.sh --op add --value <v> --file <repo>/.aid/knowledge/external-sources.md`;
  `external-source.remove` -> `write-external-source.sh --op remove --value <v> --file
  <repo>/.aid/knowledge/external-sources.md`. Both carry `target: {}` (present-but-empty,
  project-scoped, consuming feature-002's `settings.set` shape), consume no `work_id`, and the
  `--file` path is built server-side from `<id>`->repo (SEC-2, verbatim from `id_map`) -- never from
  the body. argv is an ARRAY.
- Add the per-op arg-schema (validated server-side before any spawn): `args.value` required, length
  1-2048, matching the SAME alphabet the KB lint accepts -- a URL (`^https?://\S+$`) or a
  whitespace-free path/glob (`^\S+$`) -- with no newline and no `|`; fail -> 422 `invalid-value`
  before spawn (the writer re-validates as defense in depth). The feature-001 status map applies
  unchanged (403/400/404/422/409/500). No new route, no new gate, no in-process fs write (SEC-3), no
  agent import (SEC-4).

**Acceptance Criteria:**
- [ ] `parse_external_sources` / `parseExternalSources` delegate to the existing
  `parse_doc_frontmatter` (no new frontmatter parser), drop `(none)`, dedupe preserving order, and
  return `[]` for an absent file; the two twins produce byte-identical output over a shared fixture
  set. (feature-010 AC2)
- [ ] `RepoInfo` gains `external_sources: list[str]` surfaced under `model.repo.external_sources` in
  the DM-1 `/r/<id>/api/model` envelope and absent from the DM-2 `/api/home` model.
- [ ] The DM-1 serializer twins emit the `external_sources` key without bumping `schema_version`;
  regenerated golden fixtures keep `test_server_py.py` / `test_server_node.mjs` green (byte-parity).
- [ ] After a task-020 write, the wrapper surfaces exactly the normalized contiguous-block entries
  (an entry made unreadable by a non-contiguous block or inline comment is treated as the known
  parser boundary, not silently mangled). (feature-010 AC2)
- [ ] `OP_TABLE` (both twins) carries `external-source.add` and `external-source.remove` with the
  argv arrays above; both send `target: {}`, resolve `<repo>/.aid/knowledge/external-sources.md`
  server-side from `<id>` (never from the body), and consume no `work_id`.
- [ ] The per-op arg schema validates `args.value` (length 1-2048; URL or whitespace-free path/glob;
  no newline/`|`) BEFORE any spawn, returning 422 `invalid-value` on a violation; argv is an array
  and the feature-001 status map applies unchanged. (feature-010 AC1)
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
