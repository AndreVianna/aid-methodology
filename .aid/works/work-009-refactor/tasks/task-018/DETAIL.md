# task-018: Update the Knowledge Base to the YAML state format

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-018/STATE.md` -- this task's mutable cells live
only in the work-root state file's `### Tasks lifecycle` table.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-017

**Scope:**
- Six KB docs, updated to state the shipped format, path and review status (FR-11):
  - `.aid/knowledge/artifact-schemas.md` -- `§ State-File Hierarchy` (both layout trees),
    `§ Work STATE.md`, `§ Delivery STATE.md`, `§ Task STATE.md` (headings and bodies retargeted to
    `STATE.yml`, the zone mapping restated as YAML keys, DERIVED views documented as absent from
    disk), `§ Task DETAIL.md`'s pointer to where mutable state lives, `§ How Artifacts Relate`, and
    the `§ Validation` points table.
  - `.aid/knowledge/pipeline-contracts.md` -- the on-disk work hierarchy and every per-skill state
    machine that names the file or a retired section.
  - `.aid/knowledge/quality-gates.md` -- the reviewer surface: state files are not reviewable
    artifacts, `grade.sh` is unchanged, and the new review-surface suite is named as the test
    coverage for that claim, in the `**Test coverage.**` form this doc already uses -- and NOT added
    to `§ Mechanical Gates Run by the Orchestrator`, whose table lists only orchestrator-run scripts
    (`kb-citation-lint.sh`, `lint-frontmatter.sh`, `build-kb-index.sh`, `closure-check.sh`,
    `check-version-sync.sh`) and names no review-surface suite today: the new suite is discovered by
    `tests/run-all.sh`, like the existing `test-kb-review-surface.sh`.
  - `.aid/knowledge/architecture.md` -- the canonical -> profiles render statement and the Polyglot
    parity statement as they apply to the new parse path.
  - `.aid/knowledge/module-map.md` -- the dashboard reader/server modules whose functions changed or
    were deleted.
  - `.aid/knowledge/test-landscape.md` -- the suite inventory (the new conformance corpus, the new
    cross-format characterization suite, the new review-surface suite) and the coverage-parity gate
    note about a corpus-wide re-bootstrap.
- Record in the KB the ordering rule this work established: **hierarchy migration first, format
  conversion second** (`SPEC.md § L-6`), and the **three** same-class findings carried forward rather
  than fixed (`cleanup-classify.sh`'s `> **Status:**` / `## Deploy Status` signals;
  `dashboard/scripts/delete-pipeline.sh`'s fail-open on a genuinely missing state file, where
  `_frontmatter_value` returns empty for an absent file (`:166`) and the `Running` guard fires only
  on the exact string, so a work folder with no state file has always been deletable; the work-level
  `parse_quick_check_findings` / `parse_delivery_gate` detail-view parsers) -- routed onward as
  items in `.aid/knowledge/tech-debt.md`, the KB's living findings inventory, not silently dropped
  (`SPEC.md § L-12`). Each is recorded as *carried*, and none as fixed: repairing any of them would
  be an observable behavior change a `restructure` forbids.
- **Hard constraints on this task** (`CLAUDE.md`, C-7, SP-15): no KB doc may name this work or its
  folder path -- not `work-009`, not `.aid/works/work-009-*/`, not "added in work-009" -- in prose,
  tables, headings or frontmatter. Cite the durable artifact on disk instead. No `## Change Log` /
  `## Revision History` section and no `changelog:` frontmatter field is added to any doc that lacks
  one, and no KB doc cites `CLAUDE.md`/`AGENTS.md` by line.
- `.aid/knowledge/STATE.md` (the discovery-area ledger) stays markdown and stays a KB document with
  `kb-category: meta` -- untouched except where a doc's prose must now distinguish it from the
  converted work-tree files.
- Final-state summaries refresh ONCE, here, at the end of the work: regenerate
  `.aid/knowledge/INDEX.md` (`build-kb-index.sh`) and `kb.html`. Mid-work staleness was correct.
- OUT of this task: canonical skills/templates/agent-context prose (task-014); the tests
  (task-013/015/016); the render (task-017).

**Acceptance Criteria:**
- [ ] All six KB docs state the new filename, the YAML zone mapping (FRONTMATTER keys lifted,
      AUTHORED sections as YAML structures, DERIVED views absent from disk) and the review status
      (FR-11, SP-15).
- [ ] `grep -rn 'STATE\.md' .aid/knowledge/` returns only the out-of-scope discovery-area ledger and
      explicitly labelled legacy/migration references; every remaining hit is enumerated with its
      reason (SP-15).
- [ ] No KB doc names this work or its folder path anywhere -- prose, tables, headings or
      frontmatter (C-7, SP-15, `CLAUDE.md`).
- [ ] The retired heading names (`## Lifecycle History`, `### Tasks lifecycle`, `## Tasks State`,
      `## Delivery Gate`, `## Quick Check Findings`) survive in the KB only where a doc explicitly
      labels them as the retired legacy form (SP-15).
- [ ] `artifact-schemas.md § Validation` names the machine checks that actually exist -- the writer's
      enum validation and the conformance corpus -- and does NOT claim a JSON Schema or a CI schema
      gate (A-5).
- [ ] `quality-gates.md` states that state files are never in `{{ARTIFACTS}}` and that `grade.sh` is
      unmodified, and names the new review-surface suite (SP-13, FR-10d).
- [ ] `test-landscape.md` lists the three added suites and the coverage-baseline re-bootstrap
      (SP-16).
- [ ] The three carried findings are recorded in `.aid/knowledge/tech-debt.md`, each with its
      evidence path, and none is described as fixed (`SPEC.md § L-12`).
- [ ] The KB mechanical gates pass: `kb-citation-lint.sh`, `lint-frontmatter.sh`, `build-kb-index.sh`
      freshness and `closure-check.sh` (`quality-gates.md § Mechanical Gates Run by the
      Orchestrator`).
- [ ] `INDEX.md` and `kb.html` are regenerated exactly once, in this task, after every other content
      change has landed.
- [ ] Every claim is verified against the shipped tree rather than from memory, and every cite
      resolves to a real path/section (`task-type-rules.md § DOCUMENT`).
- [ ] All section-6 quality gates pass.
