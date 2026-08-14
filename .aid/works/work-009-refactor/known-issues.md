  non-DERIVED home.

  **General lesson for the ordering rule:** the render fan-out (which installs the new writer into
  `.claude/`) must not run before the live-work conversion when the pipeline dogfoods its own writer
  on an in-flight work. For a normal adopter this never bites (they are not mid-work on the AID repo
  itself); for this self-hosting delivery it does.
- **See also:** not catalogued in `tech-debt.md`

## KI-009: full-layout work-level `## Cross-phase Q&A` (work-owner-authored channel) has no YAML home -- blocks conversion of any full work that uses it

- **Type:** Design gap (specialization of KI-006)
- **Severity:** High
- **Affects:** the converter (task-008) + the full-layout target shape (SPEC.md D-2/D-4, line ~361);
  surfaced live by `work-005-knowledge-graph` during task-010.
- **Source:** `bin/aid` `_aid_sc_convert_work_body` (full layout does NOT call `_aid_sc_emit_qa`
  and guards `## Cross-phase Q&A` as DERIVED-narrative, lines ~2733-2754) vs the current markdown
  schema (`artifact-schemas.md § Work STATE.md`), which explicitly permits work-owner-authored Q&A
  at the work level in FULL layout (channel "(b)").
- **Description:** work-009's SPEC decided `## Cross-phase Q&A` keeps a YAML key ONLY on the
  flattened Lite path (where it is AUTHORED); on the FULL path it is treated as pure DERIVED and
  must be empty. But the live markdown schema supports work-owner-authored Q&A at the work level in
  BOTH layouts. `work-005-knowledge-graph` is a live FULL-layout work carrying **29 substantial
  work-owner-authored Q&A entries** (Q1-Q28, ~1,000 lines of design-decision log) in its work-level
  `## Cross-phase Q&A`. The converter's DERIVED-narrative guard refuses that file
  ("conversion refused for this file (nothing dropped)"), so the work cannot be converted without
  either (a) giving full-layout work-level Q&A a YAML home, or (b) relocating/removing the entries.
  Its 36 child files (delivery + 35 tasks) DO convert -- so an unguarded run would leave the work in
  two formats (broken). The `migrate-work-hierarchy` remedy the WARN suggests does not apply: the
  work already has a hierarchy; the Q&A is legitimately authored, not un-migrated data.
- **Decision taken (task-010):** **work-005 deferred** by owner decision -- left fully as markdown
  (untouched, not half-converted), reads back-compat with graceful degradation. Only work-009
  (this work, flat layout) was converted. work-005's cutover is deferred until this gap is resolved.
- **Remedy (for the follow-up optimization work, which is redesigning where Q&A/audit lives):**
  give full-layout work-level Q&A an authored YAML home (keep the `qa:` key on the full path as a
  work-owner-authored channel), OR formally drop the work-level authored-Q&A channel in the schema
  and provide a relocation step. This is a SPEC + converter + both-reader-twins change, out of
  scope for work-009's plain translation.
- **See also:** [[KI-006]] (parent class -- writes with no YAML schema home); not catalogued in
  `tech-debt.md`
