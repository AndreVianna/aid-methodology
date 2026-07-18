# Known Issues

<!-- Scoped to this work. Only issues that affect features in this work. -->
<!-- Created/updated by aid-specify during codebase exploration. -->
<!-- Consumed by aid-plan for deliverable sequencing. -->

## KI-001: settings.yml is parsed by four divergent ad-hoc readers with no shared schema

- **Type:** Bug
- **Severity:** Medium
- **Affects:** feature-001-write-infrastructure, feature-002-project-header-edit, feature-005-display-rename, feature-006-task-notes (the settings.set output-charset guard — reject `"`/`\`/newline — was extended to the rename/notes validators during the delivery-001 gate)
- **Source:** `dashboard/server/server.py:347` (`_read_settings`), `dashboard/server/server.mjs:380` (`readSettings`), `dashboard/reader/parsers.py` / `dashboard/server/reader.mjs:594` (`parseProjectName`), `.claude/aid/scripts/config/read-setting.sh:139` (`lookup`)
- **Description:** `project.name` / `project.description` are read by at least four
  independent, hand-rolled parsers, each with slightly different quote-handling
  (`_read_settings` does a bare `.strip('"').strip("'")`; `read-setting.sh` strips a
  single surrounding quote pair; none reverse single-quote doubling). This feature adds a
  *writer* (`write-setting.sh`) for exactly these keys, and AC2 (truthful re-render)
  requires the written value to round-trip back through the display readers unchanged. Any
  divergence in quoting/escaping between the writer and any one reader shows a wrong value
  on the dashboard after a successful write. The feature contains the blast radius by
  constraining the writer's output alphabet to what every reader strips identically (bare
  or double-quoted scalar; reject embedded `"`/`\`/newline), but the underlying divergent-parser
  hazard remains and should be unified (single settings accessor) as follow-up.
- **See also:** not yet catalogued in `tech-debt.md`.

## KI-002: `aid update self` mutates the running dashboard server's own code (no hot reload)

- **Type:** Limitation
- **Severity:** Medium
- **Affects:** feature-004-update-tools
- **Source:** `bin/aid:1196` (`assets_dir="$AID_CODE_HOME/dashboard"` — server launch tree),
  `bin/aid:2856` (`_cmd_update_self`); restart-advisory copy `dashboard/index.html:516–521`
- **Description:** The `tools.update-self` op runs `aid update self`, which reinstalls the
  channel package at `$AID_CODE_HOME` — the very tree the running dashboard server
  (`server.py` / `reader.mjs`) was launched from. The process keeps executing the
  already-loaded pre-update code until `aid dashboard stop && aid dashboard start`; there is
  no in-process hot reload (out of scope). Mitigations shipped with the feature: the success
  toast advises restarting `aid dashboard` (reusing the existing "Assets out of date …" copy),
  and the op is idempotent + best-effort (a failed self-update leaves the old CLI intact).
  Affects sequencing: the "Update CLI" control must not ship without the restart-advisory UI
  notice.
- **See also:** SPEC.md §Security Specs ("Known hazard"), AC1b; not yet catalogued in `tech-debt.md`.

## KI-003: Node runtime blocks its single event loop for the whole `aid update` duration

- **Type:** Limitation
- **Severity:** Medium
- **Affects:** feature-004-update-tools
- **Source:** `dashboard/server/server.mjs:880` (`createServer`, single event loop) vs.
  `dashboard/server/server.py:1150` (`ThreadingHTTPServer`); feature-001 synchronous dispatch
  (`execFileSync` / `spawnSync`)
- **Description:** feature-001's child dispatch is synchronous. On the Python runtime each
  request runs on its own thread, so a long `aid update` does not stall polling; on the Node
  runtime the synchronous child **blocks the whole server** for the update's duration
  (potentially minutes) — all requests and polling freeze. Judged an acceptable UX freeze for a
  single-user, infrequent, explicitly-triggered op (see SPEC §High-stakes assumptions A1),
  mitigated by the UI busy-state + button disable and the 600 s ceiling only; no async job
  machinery is introduced (would over-engineer it).
- **See also:** SPEC.md §Security Specs ("Known limitation"), §High-stakes assumptions A1; not
  yet catalogued in `tech-debt.md`.

## KI-004: `aid`-CLI invocation + repo-card action row must be shared, not re-invented, across features 003/004

- **Type:** Coordination (cross-feature dependency)
- **Severity:** Medium
- **Affects:** feature-004-update-tools, feature-003-project-registry, feature-001-write-infrastructure
- **Source:** SPEC.md §Layers & Components + §Migration (shared CLI helper); §UI Specs
  ("Cross-feature UI coordination"); feature-003 SPEC §Layers (`aid` self-location) + its
  status_map integration requirement on feature-001
- **Description:** Both feature-004 (`tools.update`, `tools.update-self`) and feature-003
  (`project.add`, `project.remove`) shell out to the `aid` CLI via a deterministic resolver +
  argv-array dispatch, and both add a per-repo-card action row to `index.html`. Three things
  MUST be single-sourced rather than independently invented: (1) the `aid`-resolver + child
  dispatch helper (server), (2) the `card-actions` sibling-row scaffold that carries "Update
  Tools" and "Remove Project" (UI), and (3) an optional per-op `status_map` override on
  feature-001's OP_TABLE row schema (needed because the `aid` CLI uses a different exit alphabet
  than `writeback-state.sh` — feature-003 already flagged this against feature-001, which is
  graded). Affects sequencing: whichever of 003/004 lands first must introduce the shared helper
  + scaffold, and feature-001's OP_TABLE schema must carry the `status_map` hook.
- **See also:** feature-003 SPEC.md §Layers / status_map note; not yet catalogued in `tech-debt.md`.

## KI-005: dashboard becomes a second writer of `external-sources.md` frontmatter, contradicting Scout's documented single-writer invariant (silent-data-loss path)

- **Type:** Coordination (cross-subsystem ownership conflict)
- **Severity:** High
- **Affects:** feature-010-external-sources-list, `aid-discover` ELICIT/GENERATE (Scout)
- **Source:** `canonical/skills/aid-discover/references/state-elicit.md:119` ("Scout remains its
  single writer"), same file line 115 (on an ELICIT E1 path-set change, "Scout fully rewrites the
  doc (including frontmatter) on its next pass regardless"); feature-010 SPEC.md §Migration / New
  Plumbing ("KB follow-up (REAL …)"); STATE.md Cross-phase Q&A Q6
- **Description:** feature-010's OQ-P4 resolution makes the dashboard a **second writer** of
  `.aid/knowledge/external-sources.md`'s frontmatter `sources:` list (via the new
  `write-external-source.sh`), but `aid-discover`'s `state-elicit.md` documents Scout as that file's
  **single** writer and says an ELICIT E1 reset wholesale-rewrites the frontmatter on the next pass.
  This is a genuine silent-data-loss path: a dashboard-added `sources:` entry survives the immediate
  dashboard round-trip (satisfying feature-010's AC1/AC2 *within* that round-trip) but can be
  overwritten and dropped by a later discovery GENERATE pass that has no knowledge of it — so AC1's
  persistence guarantee does not extend across a subsequent Scout run. Not resolvable by writer
  plumbing alone; needs a human decision on the ownership model, e.g. (a) make Scout's rewrite
  merge/preserve dashboard-managed `sources:` entries, (b) mark dashboard-added entries so Scout
  retains them, or (c) accept the loss and re-document `external-sources.md` as discovery-owned with
  dashboard edits declared explicitly transient (softening feature-010's AC1 wording). The "single
  writer" language in `state-elicit.md` must be reconciled with feature-010's shared-ownership
  reality. **RESOLVED (2026-07-17, STATE.md Q6):** external-sources.md is discovery-owned — Scout is
  the AUTHORITATIVE writer (may overwrite/update, incl. wholesale rewrite, on any run); the dashboard
  is a SUBORDINATE maintainer doing ATOMIC single-entry edits (never a whole-file rewrite), whose
  entries Scout may drop on its next run (accepted). No `/aid-discover` behavior change; feature-010
  is UNBLOCKED for EXECUTE. Residual follow-up (post-ship KB-DELTA, not blocking): reconcile
  `state-elicit.md`'s "single writer" wording to "authoritative writer; dashboard makes subordinate
  atomic edits."
- **See also:** STATE.md Cross-phase Q&A Q6; feature-010 SPEC.md §Migration / New Plumbing; not yet
  catalogued in `tech-debt.md`.

## KI-006: per-project "Update Tools" (tools.update) silently reaches `aid`'s self-update-if-stale preamble (code-mutating, no TTY gate)

- **Type:** Bug / hazard (undocumented code-mutating side effect)
- **Severity:** Medium
- **Affects:** feature-004-update-tools (per-project `tools.update` op)
- **Source:** `bin/aid:3094-3099` (self-update-if-stale preamble runs for every non-`self` `aid update`), `bin/aid:475`/`:490-517` (`_cmd_update_self` mutates the installed CLI), `:2839-2917`; feature-004 SPEC.md §Security Specs "Known hazard"
- **Description:** The per-project "Update Tools" control dispatches `aid update` (all installed tools). Before updating tools, `bin/aid`'s self-update-if-stale preamble runs unconditionally for every non-`self` `aid update` invocation and can silently self-update the installed CLI with no TTY gate — the same code-mutating hazard KI-002 documents for the explicit `aid update self` control, but reachable from the per-project button without the restart-advisory that the self-update control carries. feature-004's SPEC now documents this (Security Specs / Feature Flow / Data Model / UI Specs / AC1) with a conditional restart-advisory mitigation; registered here for plan/execute tracking. Related to KI-002 (same underlying self-mutation) and KI-003 (Node event-loop block during `aid update`).
- **See also:** KI-002, KI-003; feature-004 SPEC.md §Security Specs; feature-001 write-gate (server stays LLM-free, argv-array child dispatch).

## KI-007: reader `_reconcile_same_work` per-task union-merge can source a reconciled task field from a different work copy than the write targeted (duplicate work_id across worktrees)

- **Type:** Latent correctness (pre-existing reconcile behavior; only manifests under duplicate work_id across worktrees)
- **Severity:** Low
- **Affects:** feature-008-execution-control (stop/resume signal read-back); latent for feature-001 `task.set-notes` and any per-task write today
- **Source:** `dashboard/reader/reader.py:131` `_reconcile_same_work` (per-task union-merge, most-advanced SD2 rank per task_id) vs. the work-level "Pipeline State winner" that feature-001's `resolve_work_dir` mirrors for writes; feature-008 SPEC.md:157-164 (KI-008-D residual)
- **Description:** Writes resolve to the work-level newest-`updated` winner (via `resolve_work_dir`), but the reader reconciles TASK rows by a per-task most-advanced union across all worktree copies — independent of the work-level winner. In the pathological case of the SAME `work_id` existing across multiple worktrees, a reconciled task field (e.g. a freshly-written `stop_requested`/`notes`) could be rendered from a different copy than the one just written, a same-render AC2 drift. Root cause is feature-001's pre-existing reconcile mechanism (applies to `task.set-notes` today), NOT introduced by feature-008. Confirmed NOT present in work-017's live topology (no duplicate work_id across worktrees today); flagged OOS by the feature-008 review. Track for plan/execute; a fix belongs in feature-001's reconcile/resolve alignment, not feature-008.
- **See also:** feature-008 SPEC.md (KI-008-D); feature-001 SPEC.md `resolve_work_dir` / WT-1; KI-001 (reader divergence class).
