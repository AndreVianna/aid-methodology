# task-005: discovery-reviewer — doc-count contradiction + ledger complete-table contract (D3+D4)

**Type:** DOCUMENT

**Source:** work-002-canonical-bug-fixes → delivery-001

**Depends on:** — (none)

**Scope:**
Both fixes are in `canonical/agents/discovery-reviewer/AGENT.md`. One review unit.

- **D3 — doc-count contradiction (~lines 94, 206).** The file says "14 primary KB docs" in one place
  and the meta-docs are "derived from the 16 primary KB docs" in another. Correct both to the
  disk-verified count: `canonical/templates/knowledge-base/` holds 15 `.md` files minus `README.md`
  = **14**. Verify with `ls canonical/templates/knowledge-base/*.md | wc -l` and check there is no
  third stale count elsewhere in the file.

- **D4 — ledger heredoc complete-table contract (~lines 232, 251).** The `## ⚠️ File Writing` section
  writes the ledger with `cat > … << 'LEDGEREOF'` (a full overwrite) and shows only a single-row
  example, while the Output contract prose says "you append rows" — read literally on cycle 2 that
  truncates prior findings. Clarify:
  - `cat >` rewrites the whole file, so the heredoc body MUST contain the complete table — all prior
    rows carried forward with updated Status, plus the new rows.
  - `cat >>` (append) is wrong for the ledger (duplicates the header, can't update a prior Status).
  - Replace the example with a cycle-2 ledger (prior rows preserved with changed Status + appended
    new Pending rows).
  - Leave the separate Q&A-file `cat >>` guidance intact, and do not touch the grade routing at
    line ~226 (already correct — D5 is out of scope).

**Acceptance Criteria:**
- [ ] D3: both references state the same disk-verified count (14); no other count in the file disagrees.
- [ ] D4: the File Writing section states the heredoc must contain the full carried-forward table and
      that `cat >>` is wrong for the ledger; the example shows a cycle-2 rewrite; the Q&A `cat >>`
      guidance is unchanged.
- [ ] All §6 quality gates pass.
