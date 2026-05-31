# task-006: Register delivery-001 (P0 baseline) in the Knowledge Base

**Type:** DOCUMENT

**Source:** feature-001 + feature-002 + feature-003 → delivery-001

**Depends on:** task-002, task-004, task-005

**Scope:**
- Update the authored KB docs to reflect delivery-001's now-merged reality (verify each claim against the edited canonical files):
  - `.aid/knowledge/module-map.md`: the reconciled discovery-agent ownership (scout → `project-structure.md` + `external-sources.md`; quality → `test-landscape.md`, `tech-debt.md`, `infrastructure.md`); note `document-expectations.md` is now the single per-doc expectations source the reviewer loads at dispatch.
  - `.aid/knowledge/test-landscape.md`: add the two new canonical suites (`test-discovery-doc-ownership.sh`, `test-expectations-single-source.sh`); update the suite count off the fixed "13" to the current number (state it as "currently N", not a hardcoded invariant).
  - `.aid/knowledge/architecture.md`: only if it describes discovery agent roles/ownership — align it; otherwise leave untouched.
- Regenerate `INDEX.md` via `build-kb-index.sh` and refresh the generated KB indexes (`refresh-all` per generated-files.txt) so frontmatter-derived surfaces stay current.
- Do NOT pre-document delivery-002's declared-doc-set mechanism here (that is task-013).

**Acceptance Criteria:**
- [ ] No KB doc still asserts the old scout-owns-infrastructure ownership; the reconciled ownership is reflected accurately (verified against canonical).
- [ ] `test-landscape.md` lists the two new suites and no longer hardcodes "13" as an invariant.
- [ ] `INDEX.md` regenerated; generated KB indexes current; no stale references introduced.
- [ ] DOCUMENT default criterion: accuracy verified against the current (post-delivery-001) codebase.
