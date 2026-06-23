# task-027: kb-actback-task.sh -- representative-task selector + operational-structure presence check

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-005

**Depends on:** task-008 (delivery-001), task-028 (delivery-005)

**Scope:**
- Author the NEW ASCII bash helper `canonical/aid/scripts/kb/kb-actback-task.sh` (the `aid/` path
  segment is MANDATORY -- its siblings `closure-check.sh` / `kb-teachback-questions.sh` live there;
  do NOT copy f005's as-built `state-review.md` path bug that drops `aid/`). Pure coreutils
  (`grep`/`awk`/`sort`) -- no LLM, no embedding, no `python3`/`pwsh` (C1/NFR-8). Two functions:
  - **(1) Representative-task selection.** Emit a fixed, reproducible "do this change" representative-
    task spec keyed to the project's own KB shape, reading **only machine-readable substrate**: the
    resolved `discovery.doc_set` filenames + their `present|absent` status (the resolver TSV is
    `filename<TAB>owner<TAB>presence` -- **three fields, NO concern column**, per
    `doc-set-resolve.md` L73-75/L108-110) and the first-class operational sections actually present
    (the `## Conventions`/`## Invariants`/`## Gotchas`/`## Contracts` headings from (2)). The
    concern->task-shape mapping is a documented **tuning HINT in a comment, never a parsed field**.
    The exact task-shape heuristic is the calibrated surface deferred via **[SPIKE-A1]** (f012-tuned
    against the act-back fixtures); this task fixes the deterministic substrate (filenames + presence
    + present sections -> same KB shape yields same task, byte-reproducibly) and the *shape*, not the
    final heuristic weights.
  - **(2) Operational-structure presence check.** For each Full-Primary KB doc, grep the named
    operational sections and emit a per-doc table `doc | class | present|absent` (mirroring
    `closure-check.sh`'s coverage-table shape). **Scoped per f003's owning-table** (consume the
    `concern-model.md` four-classes->owning-concerns->docs map authored in task-028) so each doc is
    reported `present|absent` ONLY for the classes it is *expected* to own (a `domain-glossary.md`
    that owns no Contracts is NOT reported `## Contracts absent`). Stable-sorted, byte-reproducible.
- Consume `closure-check.sh`'s output-shape conventions (task-008, delivery-001) as the sibling table
  format to mirror, and task-028's owning-table (the `concern-model.md` four-classes->owning-concerns
  ->docs map) to scope the presence check. This helper reads filenames + `present|absent` status +
  operational sections, NOT frontmatter, so f001's `extract_field`/`extract_list` (task-002) is NOT a
  dependency. Do NOT read project source.

**Boundary (this task ships ONLY the helper):** it does NOT wire M6 into `state-review.md` (task-029),
does NOT author the doc-model rule or the owning-table (task-028 -- this script *consumes* it), does
NOT author `reviewer-prompt-actback.md` or the `[ACTBACK]` rubric tag (task-029), and does NOT build
the end-to-end pass/fail-KB corpus (delivery-006/f012). It edits NO f003/f005 machinery.

**Acceptance Criteria:**
- [ ] `canonical/aid/scripts/kb/kb-actback-task.sh` exists at the `aid/`-segment path, is pure
  coreutils (no `python3`/`pwsh`/binary/LLM), ASCII-only, and is added to `test-ascii-only.sh`'s
  `SHIPPED_SCRIPTS` allow-list (the allow-list edit; the assertion suite is task-030).
- [ ] Function (1) emits a representative-task spec deterministically over the machine-readable
  substrate (doc-set filenames + `present|absent` + present operational sections); the same KB shape
  yields a byte-identical task spec on re-run. It parses NO concern field (the resolver TSV emits
  none); any concern->task-shape mapping appears only as a code comment tagged the [SPIKE-A1] tuning
  hint.
- [ ] Function (2) greps the named operational sections (`## Conventions`/`## Invariants`/
  `## Gotchas`/`## Contracts`, per `concern-model.md`'s enumerated headings) per Full-Primary doc and
  emits a stable-sorted `doc | class | present|absent` table, **scoped to the classes each doc is
  expected to own** via task-028's owning-table (no over-report of legitimately-absent classes).
- [ ] Output is stable-sorted and byte-reproducible across runs (NFR-3); a re-run over the same input
  produces identical bytes.
- [ ] The script invocation/path follows the working `state-generate.md`/`state-closure.md` render-
  token convention (full `canonical/aid/scripts/kb/...` form), not f005's `state-review.md` dropped-
  `aid/` mistake.
- [ ] All section-6 quality gates pass (unit-level coverage for both functions over a tiny in-script
  or in-suite fixture; the full canonical assertion suite is task-030; build passes).
