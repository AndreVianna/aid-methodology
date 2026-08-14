function deriveLifecycle({ workDir, tasks, pendingInputs, stateText, workId, latestHistoryDate }) {
  // LC-3 fallback derivation (mirrors derivation.py derive_lifecycle;
  // UNCHANGED aside from the `updated` slot, task-004 note below). Called
  // ONLY when the STATE.yml document carries no `lifecycle` key at all.
  //
  // The `updated` slot (6th return element) is `latestHistoryDate`, computed
  // ONCE by the caller (parseStateMd) via computeLatestHistoryDate() over
  // the already-parsed `lifecycle_history` array -- NOT re-derived per
  // branch. This is the one deliberate divergence from the Python twin's
  // `derive_lifecycle`, which still calls its own `_extract_latest_history_
  // date(state_text)` (a raw "## Lifecycle History" markdown-table scan)
  // identically in all five branches: that scan has no construct left to
  // match in a STATE.yml document (the table is gone; lifecycle_history is
  // a YAML list), so it is dead code there, kept only because
  // derivation.py's own body is out of task-003/task-004's edit surface.
  // Node has no such module boundary, so this task replaces the equivalent
  // dead scan with a live computation over structured data instead of
  // porting the dead scan verbatim (see computeLatestHistoryDate's comment