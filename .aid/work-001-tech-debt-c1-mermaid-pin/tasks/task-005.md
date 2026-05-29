# task-005: HTML summary cascade-update for C1 closure

**Type:** DOCUMENT

**Source:** work-001-tech-debt-c1-mermaid-pin → delivery-001

**Depends on:** task-001, task-002, task-003, task-004

**Status:** In Progress

**Why this task exists:** task-004 swept the KB markdown but missed `summary-src/sections/*.html`. The user-visible `knowledge-summary.html` still presents C1 as an open CRITICAL with the pre-fix description, claims 5 test suites instead of 6, and counts 235 total assertions instead of 254. The KB-truthfulness invariant says the HTML must match current KB; task-004's "Machine Grade still A+" framing was a category error (validators check format, not content truth).

**Scope:**

Edit the `summary-src/sections/` files, re-assemble, re-validate:

- **`sections/10-tech-debt.html`**:
  - Tech-debt summary stat row: Critical count `1` → `0`.
  - C1 detail card: move to a RESOLVED row (or change marker class from `crit` to `resolved`); description rewritten to "RESOLVED 2026-05-29: Pinned to v11.15.0; SHA verified on both cache-hit and post-download paths; .meta treated as untrusted."
  - H3 detail card: drop "sibling of C1" framing.

- **`sections/09-test-landscape.html`**:
  - Lede: 5 → 6 suites; 235 → 254 assertions.
  - Suite table: add a row for `fetch-mermaid.sh` (Target: `canonical/scripts/summarize/fetch-mermaid.sh` + `tests/canonical/fetch-mermaid.sh`; Assertions: **19**; Notable coverage: 4 scenarios — cache-hit tamper, post-download tamper, clean fast path, compute_sha256 'unknown' fallback).

- **Other sections:** grep for `mermaid@latest`, `registry.npmjs`, `supply.chain` references — sweep anything else stale.

- Run `bash .claude/scripts/summarize/assemble.sh` to rebuild `knowledge-summary.html`.

- Run `bash .claude/scripts/summarize/run-validators.sh .aid/knowledge/knowledge-summary.html` and confirm Machine Grade ≥ A.

**Acceptance Criteria:**
- [ ] `sections/10-tech-debt.html` no longer shows C1 as an open Critical.
- [ ] `sections/10-tech-debt.html` Critical count stat is 0.
- [ ] `sections/10-tech-debt.html` H3 description no longer says "sibling of C1".
- [ ] `sections/09-test-landscape.html` lists 6 suites with 254 total assertions.
- [ ] `sections/09-test-landscape.html` includes a row for the new `fetch-mermaid.sh` suite with 19 assertions.
- [ ] Re-assembled `knowledge-summary.html` exists and renders.
- [ ] `run-validators.sh` reports Machine Grade ≥ A (A+ expected since only content changes, not format).
- [ ] Grep across `summary-src/sections/` for `mermaid@latest` / `registry.npmjs.org/mermaid` returns ZERO live claims (only historical mentions inside resolved-item context, if any).
- [ ] All §6 quality gates pass.
