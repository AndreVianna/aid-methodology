# task-002: extract_list parser + backward-compatible INDEX emission + generator re-run

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-001

**Scope:**
- Add the `extract_list` helper to `canonical/aid/scripts/kb/build-kb-index.sh`: a YAML reader
  that handles BOTH inline lists (`tags: [a, b]`) and block lists (`tags:\n  - a\n  - b`), used
  for `tags`/`see_also`/`audience`/`sources`. `objective:`/`summary:` keep using the existing
  `extract_field` (single-line scalars). This is the one net-new parser primitive.
- Parse the new fields; keep the INDEX emission BACKWARD-COMPATIBLE: continue to emit the current
  INDEX shape (NO routing-table render -- that is delivery-002/f002), falling back
  `objective`->`intent` when `objective:` is absent, and emit an empty cell for any absent optional
  field, so an un-migrated KB still produces a valid INDEX.
- Re-run `python .claude/skills/generate-profile/scripts/run_generator.py` and commit the
  regenerated `profiles/` (resolves SPIKE-3: verify no emission manifest pins the old
  `build-kb-index.sh` byte-shape; if it does, regen, never hand-edit). Confirms SPIKE-1 (the table
  render lands in d002) and SPIKE-4's day-one degrade path.

**Acceptance Criteria:**
- [ ] `extract_list` parses both inline (`[a, b]`) and block (`- a`) YAML lists for
  `tags`/`see_also`/`audience`/`sources`; `objective:`/`summary:` still resolve via `extract_field`.
- [ ] `build-kb-index.sh` parses all 8 new fields without error on a doc carrying them.
- [ ] INDEX emission is byte-stable in the CURRENT (pre-table) shape; it does NOT render the f002
  routing table.
- [ ] On a doc lacking `objective:`, emission falls back to `intent:`; absent optional fields emit
  an empty cell -- an un-migrated KB still produces a valid INDEX (the "INDEX.md is fresh" CI step
  stays green).
- [ ] AID's own `INDEX.md` is regenerated and committed in this change (INDEX-fresh green).
- [ ] `run_generator.py` re-run and regenerated `profiles/` committed; no rendered copy hand-edited
  (render-drift green).
- [ ] Unit-level assertions for `extract_list` (inline + block forms) are exercised by the
  canonical suite or an in-script self-test; all existing tests still pass.
- [ ] All section-6 quality gates pass.
