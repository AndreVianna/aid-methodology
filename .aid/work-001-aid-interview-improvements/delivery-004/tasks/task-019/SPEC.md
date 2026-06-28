# task-019: Forward-authored freshness short-circuit in kb-freshness-check.sh

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-004

**Depends on:** -- (none)

**Scope:**
- The ONE behavioral edit of the `source: forward-authored` marker (C-1). In
  `canonical/aid/scripts/kb/kb-freshness-check.sh`, add a `source: forward-authored` short-circuit so a
  design-authoritative seed doc is never run through the source->doc drift algorithm (a forward-authored
  doc leads; code conforms, so a listed intent-source changing must NOT flip it to `suspect`).
- Edit location per feature-003 SPEC: in `check_doc()`, **before the absence gate** (before the
  `approved_at_commit` read at line ~285), read the doc's `source` via the existing `fm_scalar` helper;
  when `source == forward-authored`, emit verdict `current` with `n_current=n_suspect=n_unknown=0` and a
  detail/reason string `"design-authoritative (forward-authored): source-drift N/A -- see feature-005
  conformance check"`, then `return`. Emit correctly for BOTH `--format tsv` (the 7-column row:
  doc-relpath, `current`, approved_at_commit-value-or-empty, `0`, `0`, `0`, empty suspect-csv) and
  `--format text`.
- Reuse the EXISTING verdict enum `{current, suspect, unknown}` -- no enum value is added or changed, so
  existing TSV consumers keep working. `should_check()` already routes `primary|extension` non-generated
  docs in-scope, so a forward-authored doc reaches `check_doc()`; do NOT add a skip branch in
  `should_check()` (a seed doc MUST still be processed -- it folds to `current`, it is not skipped).
- Keep the script `set -eu`-clean, dependency-free (awk/git only), read-only (stdout only), and ASCII-only.
- **Out of scope:** the schema enum row + lint/index comments (task-020); the verifying tests (task-021);
  the generator render (task-026).

**Acceptance Criteria:**
- [ ] `check_doc()` reads `source` before the absence gate and, for `source: forward-authored`, returns verdict `current` with `n_current=n_suspect=n_unknown=0` and the documented design-authoritative reason, in BOTH tsv and text formats. *(C-1, DoD D1; gate criterion 2)*
- [ ] A forward-authored doc whose listed `sources:` changed after `approved_at_commit` still folds to `current` (NOT `suspect`) -- demonstrating source-drift is skipped. *(feature-005 boundary; gate criterion 2)*
- [ ] No verdict-enum value is added or changed; the tsv row stays 7 columns; existing hand-authored/generated routing in `should_check()` is byte-unchanged (verify via diff). *(NFR-2 brownfield-intact, DoD D6)*
- [ ] Script stays `set -eu`-clean, read-only, dependency-free, and ASCII-only. *(IMPLEMENT defaults; bash unit coverage is added by task-021 -- the per-method unit-test default is satisfied there, not inline)*
- [ ] All REQUIREMENTS.md §6 quality gates pass (heavy gates exercised at task-027).
