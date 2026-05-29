# task-003: Close tech-debt.md C1 + add bump-procedure comment in fetch-mermaid.sh

**Type:** DOCUMENT

**Source:** work-001-tech-debt-c1-mermaid-pin → delivery-001

**Depends on:** task-001, task-002

**Status:** Pending

**Scope:**
- Mark `.aid/knowledge/tech-debt.md` item **C1** as **RESOLVED**:
  - Append `**Status:** Resolved 2026-05-29 (commit <merge-sha>)` to the C1 detailed entry.
  - Resolution note: "Pinned to v11.15.0; SHA verified on both cache-hit and post-download paths; .meta treated as untrusted."
  - Severity Summary table: decrement the Critical bucket count by 1.
- Add multi-line comment block above `PINNED_VERSION` + `EXPECTED_SHA256` in `canonical/scripts/summarize/fetch-mermaid.sh`:
  1. Where to find the current Mermaid version: `https://www.npmjs.com/package/mermaid`
  2. How to compute the new SHA: `curl -sS https://cdn.jsdelivr.net/npm/mermaid@<ver>/dist/mermaid.min.js | sha256sum`
  3. Update BOTH constants in the same edit.
  4. Verify locally: `bash tests/canonical/fetch-mermaid.sh` must pass.
- Run `python run_generator.py` to propagate the comment block to the 3 profile-tree copies.
- Verify `/aid-summarize VALIDATE` still reports Machine Grade ≥ A.

**Acceptance Criteria:**
- [ ] tech-debt.md C1 entry has `**Status:** Resolved` line with date + commit reference
- [ ] Resolution note cites: pinned version, both verify points, .meta-untrusted posture
- [ ] Severity Summary Critical count decremented by 1
- [ ] fetch-mermaid.sh has multi-line bump-procedure comment adjacent to constants
- [ ] Comment names: npmjs.com URL, curl+sha256sum command, both-constants-together rule, test re-run step
- [ ] python run_generator.py propagates comment to all 3 profile trees (verify via `git diff` + sha256)
- [ ] /aid-summarize VALIDATE Machine Grade ≥ A
- [ ] All §6 quality gates pass
