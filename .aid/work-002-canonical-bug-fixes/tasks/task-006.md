# task-006: D6 — reviewer.md: add the File Writing (heredoc) section

**Type:** DOCUMENT

**Source:** work-002-canonical-bug-fixes → delivery-001

**Depends on:** task-005

**Scope:**
- `canonical/agents/reviewer/AGENT.md` has tools `Read, Glob, Grep, Bash` (no Write) and an Output
  contract that says "append rows" (line ~74), but **no File Writing section** — no concrete, safe
  mechanism to write `.aid/.temp/review-pending/<scope>.md`. Add a `## ⚠️ File Writing` section that
  **mirrors the corrected `canonical/agents/discovery-reviewer/AGENT.md`** (per task-005):
  - Do not use the Write tool; use `cat > … << 'LEDGEREOF'` via Bash.
  - The heredoc must re-emit the complete carried-forward table (same complete-table / cycle-2
    contract as D4), so cross-cycle writes don't duplicate the header or leave stale Status — which
    would otherwise break grade computation.
- Keep `reviewer.md`'s existing Output contract, severity rules, and example table; only add the
  missing File Writing mechanism. Do not add the Write tool — the Bash heredoc is the path.
- Depends on task-005 so this section is a faithful mirror of the finalized discovery-reviewer
  contract (different files, no edit collision — this is a content-consistency dependency).

**Acceptance Criteria:**
- [ ] `reviewer/AGENT.md` has a File Writing section instructing a `cat >` heredoc with the
      complete-table contract, consistent with the corrected `discovery-reviewer/AGENT.md`.
- [ ] The guidance prevents duplicated headers and stale Status across review cycles.
- [ ] No Write tool is added (Bash heredoc remains the mechanism).
- [ ] All §6 quality gates pass.
