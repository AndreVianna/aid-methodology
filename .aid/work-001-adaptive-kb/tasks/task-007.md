# task-007: Declared-set read-path — settings schema + resolve_doc_set split + default-seed synthesis

**Type:** IMPLEMENT

**Source:** feature-004-declared-doc-set → delivery-002 (CORE wave)

**Depends on:** task-001, task-003, task-005

**Scope:**
- Add the declared-set read-path as a shared bash snippet in the discovery SKILL prose (NO new `canonical/scripts/kb/` script — reuse the existing `read-setting.sh`):
  - `resolve_doc_set`: `read-setting.sh --path discovery.doc_set` (returns the block-list comma-joined) → split on `,` then each item on `|` → emit `filename<TAB>owner<TAB>presence`.
  - Malformed-record guard: warn + skip any item missing `filename`/`owner` (defense-in-depth for the comma-in-`when` edge — fragments 2+ are skipped; fragment 1 survives with a truncated display-only `when`, which is benign).
  - Owner-enum validation with a `discovery-architect` fallback for unknown owners (non-fatal warn) (FR-P1-5).
  - `synth_default_seed`: when `discovery.doc_set` is unset, enumerate `canonical/templates/knowledge-base/*.md` paired to the §2.2 owner map (NO hardcoded list — FR-P0-4/FR-P1-2).
  - The 4 accessors: list-filenames, owner-of `<filename>`, owns-`<agent>`, resolve.
- Document the `discovery.doc_set` schema (field grammar `filename|owner|presence(required|conditional[:when])`; the no-comma-in-any-field constraint) in the SKILL/settings reference.
- Do NOT add a `discovery.doc_set` block to any shipped `canonical` settings (it is per-project data) — only the default-synthesis + split logic is canonical. Re-render with `python run_generator.py`.

**Acceptance Criteria:**
- [ ] Unset `discovery.doc_set` ⇒ resolve synthesizes the full default seed from on-disk templates (no hardcoded list); present ⇒ exact `filename owner presence` rows.
- [ ] `category` / `expectations` never appear in resolve output (resolved from frontmatter / `document-expectations.md`, not re-declared).
- [ ] Unknown owner ⇒ warn + route to `discovery-architect`, non-fatal; comma-shred fragments don't surface as wrong/unknown owners.
- [ ] The §2.2 owner map equals F1's reconciled truth; implementation is pure bash+awk over the existing `read-setting.sh` (no new script, no yq/python).
- [ ] All §6 quality gates pass (generator self-tests, render-drift clean, 13 suites green).
