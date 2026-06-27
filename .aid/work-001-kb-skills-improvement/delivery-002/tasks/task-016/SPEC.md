# task-016: ASCII-clean build-kb-index.sh + wire test-ascii-only guard + INDEX-fresh CI

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-002

**Depends on:** task-015

**Scope:**
- ASCII-clean `canonical/aid/scripts/kb/build-kb-index.sh`: replace every one of the 17 existing
  non-ASCII glyphs -- em-dashes (`-`) in comments/help text (lines 2, 17-20, 33, 45-48, 124, 134,
  167-169, 186) with an ASCII `--` (or `-`), and the check-mark emoji in the line-203 success `echo`
  with an ASCII marker (e.g. `[OK]`/`OK:`). After the edit the whole script passes
  `grep -P "[^\x00-\x7F]"` with zero matches. The table glyphs introduced by task-015 (`|`, `-`,
  backtick) are already ASCII.
- Wire the guard: add `build-kb-index.sh` to the `SHIPPED_SCRIPTS` array in `test-ascii-only.sh`
  (current lines 24-46), in the SAME change as the ASCII clean so the guard goes green immediately
  (the allow-list addition is gated on the script being ASCII-clean).
- Re-run the INDEX generator and commit the regenerated `.aid/knowledge/INDEX.md` in THIS task: the
  section-header lines ASCIIfied above (generator lines 167-169 -- `## Primary -- load-bearing
  knowledge`, `## Meta -- ...`, `## Extension -- ...`) are EMITTED verbatim into `.aid/knowledge/INDEX.md`
  (which currently carries those em-dashes at L25/L199). Run
  `canonical/aid/scripts/kb/build-kb-index.sh` and commit the regenerated (now ASCII) `INDEX.md` as part
  of the SAME change that edits the script -- f002 SPEC binds the INDEX regen to whichever change edits
  the generator, so this is NOT deferred to task-015.
- Confirm the INDEX-fresh / kb-hygiene CI step survives the format change with NO edit to the step
  itself: it is format-agnostic (regen-and-diff with the timestamp filter
  `filt='AUTO-GENERATED|Generated at:|: Generated$'`). Verify every table row ends in ` |` so the
  `$`-anchored `: Generated$` pattern never matches a cell (only the changelog `- <date>: Generated`
  line, as intended). No edit to the lint-frontmatter step (f001-owned).
- Re-run `python .claude/skills/generate-profile/scripts/run_generator.py` and commit the regenerated
  `profiles/` (the ASCII edits change every rendered host-tree copy deterministically, so this regen is
  unconditional; render-drift green; edit canonical only).
- Boundary: this task OWNS the ASCII-clean of `build-kb-index.sh` + the ASCII allow-list wiring. It
  does NOT change the table render logic (task-015) or add the canonical test suite (task-017).

**Acceptance Criteria:**
- [ ] `build-kb-index.sh` passes `grep -P "[^\x00-\x7F]"` with zero matches -- all 17 prior non-ASCII
  glyphs (em-dashes + the line-203 check-mark emoji) replaced with ASCII. *(f002 deliverable 2)*
- [ ] `build-kb-index.sh` is present in `test-ascii-only.sh`'s `SHIPPED_SCRIPTS` array; running
  `test-ascii-only.sh` passes and now covers `build-kb-index.sh`. *(f002 deliverable 3)*
- [ ] `.aid/knowledge/INDEX.md` regenerated via `build-kb-index.sh` and committed in THIS task; the
  committed `INDEX.md` is ASCII (`grep -P "[^\x00-\x7F]"` zero matches) and matches a fresh regen, so
  INDEX-fresh CI stays green after the section-header ASCII edit. *(f002 deliverable)*
- [ ] The INDEX-fresh / kb-hygiene CI step passes under the new table format with no edit to the step;
  every table row ends in ` |` so `: Generated$` cannot false-green on a cell.
- [ ] `run_generator.py` re-run and the regenerated `profiles/` committed (unconditional); no rendered
  copy hand-edited (render-drift green).
- [ ] All section-6 quality gates pass.
