# task-020: write-external-source.sh atomic single-entry writer

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

**Depends on:** task-004 (delivery-001)

**Scope:**
- Add one new canonical bash writer `write-external-source.sh`, a scriptable sibling of
  feature-001's `write-setting.sh` / `write-requirement.sh` (and of
  `.claude/aid/scripts/config/read-setting.sh`). Bash-only (the dashboard already requires bash).
  Contract:
  `write-external-source.sh --op <add|remove> --value <url|path> [--file <external-sources.md>]`
  (`--file` default `.aid/knowledge/external-sources.md`).
- Authoritative target = the frontmatter `sources:` YAML list in
  `<repo>/.aid/knowledge/external-sources.md` (the machine-readable registry per the
  `external-sources.md` template). The `## Sources` body is maintained only as a minimal managed
  bullet mirror; the writer NEVER synthesizes the rich `| Path | Type | Accessible | Key Content |`
  table (semantic columns the LLM-free server cannot fill -- OQ-P4 / discover-authoritative).
- Value validation -- `--value` must match the SAME alphabet the KB lint accepts (mirrors
  `canonical/aid/scripts/kb/lint-frontmatter.sh` `sources_entry_shape()`, line 270): a URL
  (`^https?://`) OR a whitespace-free path/glob (`^[^[:space:]]+$`); reject any whitespace, newline,
  or `|` (exit 4), so a dashboard-added entry keeps `lint-frontmatter.sh` green. `--op` other than
  `add`/`remove` exits 4.
- `add` (atomic single-entry) -- idempotent: if `--value` already present in `sources:` exit 0
  (no-op). Else insert a `  - <value>` item IMMEDIATELY under the `sources:` key line as a
  **contiguous block** (the only form `parse_doc_frontmatter` consumes -- a comment/blank line
  between `sources:` and its items ends the block; and the item line carries NO inline `# comment`,
  which the parser would not strip). If the block held only the discovery placeholder `- (none)`,
  drop it. Also add a `- <value>` bullet to the `## Sources` body mirror. This normalizes the block
  to contiguous `  - <item>` lines so every dashboard-managed entry is reader-visible (AC2). Per Q6
  the dashboard is a subordinate atomic single-entry maintainer -- never a whole-file rewrite (Scout
  stays authoritative).
- `remove` -- remove the matching `  - <value>` frontmatter item; if that empties the real list,
  write the lint-clean empty form `sources: []`. Remove the matching `## Sources` body bullet; if
  the body list empties, restore the canonical "No external documentation was provided…" paragraph.
  If `--value` is not present, exit 1 (-> 404 `not-found`, surfacing drift; an edge/racing case
  since the UI offers Remove only for listed entries).
- `## Sources` body mirror -- maintain a simple `- <entry>` bullet list bounded by a stable
  HTML-comment marker pair (e.g. `<!-- managed:external-sources -->` … `<!-- /managed:external-sources -->`).
  First add replaces the "No external documentation…" paragraph with the marked list; removing the
  last entry restores that paragraph. If a hand-authored table already exists, insert/update the
  managed bullet block adjacent to it without rewriting the human rows (body is never machine-read --
  cosmetic-truthfulness only).
- Atomicity & preservation -- surgical edit via temp file + `mv` (as `writeback-state.sh`'s
  `wb_set_frontmatter` and feature-001's writers do); every non-target line byte-preserved; the
  frontmatter block boundary is the leading `---`…`---`.
- Exit-code alphabet = feature-001's canonical OP_TABLE exit->HTTP map (the `writeback-state.sh`
  alphabet, NOT `write-setting.sh` / `read-setting.sh`'s local one which assigns exit `2` to
  arg/IO): `0` ok; `1` remove-target-absent (->404); `2` lock contention (->409 `busy`); `3`
  IO/write error (->500 `write-failed`); `4` invalid value (->422). No lock is required for
  correctness (single-file, single-user), but the writer MAY reuse the `writeback-state.sh` sentinel
  pattern for uniformity; if so, sentinel contention -> exit 2.
- Co-vendor with the dashboard unit via a single `dashboard/MANIFEST` one-line edit (same
  single-source mechanism feature-001 uses for its writers; `vendor.js`/`vendor.py`/`install.sh`/
  `install.ps1`/`release.sh` all derive from it, guarded by
  `tests/canonical/test-dashboard-manifest.sh`); the script self-locates from `$AID_CODE_HOME`.

**Acceptance Criteria:**
- [ ] `write-external-source.sh --op add --value <v>` inserts exactly one `  - <v>` item as a
  contiguous block immediately under the `sources:` key (dropping a lone `- (none)` placeholder),
  atomically via temp-file + `mv`, with no inline `# comment` on the item and every non-target line
  byte-preserved; a repeat add of a value already present is an exit-0 no-op (atomic single-entry). (feature-010 AC1)
- [ ] The added item is reader-visible: after the write, `parse_doc_frontmatter` on the file yields
  the new value in its `sources_list` (contiguous-block normalization holds). (feature-010 AC2)
- [ ] `--op remove --value <v>` removes the matching frontmatter item (writing `sources: []` when
  the real list empties) and the matching `## Sources` body bullet (restoring the canonical
  "No external documentation…" paragraph when the body list empties); removing an absent value
  exits 1.
- [ ] The `## Sources` body is maintained only as a managed bullet mirror bounded by the
  HTML-comment marker pair; the writer never emits the `| Path | Type | Accessible | Key Content |`
  table, and any pre-existing hand-authored table's rows are preserved.
- [ ] Value validation matches `lint-frontmatter.sh sources_entry_shape()` (URL `^https?://` or a
  whitespace-free path/glob); whitespace, newline, or `|` exits 4; a bad `--op` exits 4. Any accepted
  entry keeps `lint-frontmatter.sh` green.
- [ ] Exit codes follow feature-001's canonical map (`0`/`1`/`2`/`3`/`4` -> 200/404/409/500/422),
  distinct from `write-setting.sh`'s local contract.
- [ ] `dashboard/MANIFEST` lists `write-external-source.sh` and
  `tests/canonical/test-dashboard-manifest.sh` passes; the script self-locates from `$AID_CODE_HOME`.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
