# task-027: Delivery-004 verification -- greenfield gate + zero-loopback sufficiency + coherence + brownfield-intact

**Type:** TEST

**Source:** work-001-aid-interview-improvements -> delivery-004

**Depends on:** task-026

**Scope:**
- Verify delivery-004 against its gate criteria. Skills are prose-executed and not unit-tested by design,
  so this task combines running the EXISTING brownfield canonical tests + the §6 heavy gates with the AID
  AI + human-review DoD via dogfood transcripts + the reviewer checklist. It authors no new skill content.
- **(A) Greenfield-mode gate at A+ (AC-2 / NFR-3 / DoD D3):** run a code-less dogfood project end-to-end
  through the seed-authoring step (task-025): the engine elicits intent -> the 4 core docs (+ `decisions.md`
  iff rationale-bearing) are authored with `source: forward-authored` -> the review subsystem is invoked
  with `greenfield: true` and the seed traverses the FULL panel (per task-023's reconciled state-review.md)
  -> grade >= work minimum (A+, TOTAL 0) with the as-built red flags relaxed and intent-evidence accepted.
- **(B) Zero-loopback sufficiency (AC-2 / RQ-A5 / DoD D4):** run a downstream `aid-specify` (dry-run /
  dogfood) on the approved seed and confirm it completes with ZERO KB-gap loopbacks -- the objective
  sufficiency measure. Confirm the seed is minimal: the as-built exclusions (`module-map`,
  `test-landscape`, `infrastructure`, `feature-inventory`, `project-structure`, `schemas`/integration
  unless domain-promoted) are ABSENT.
- **(C) Coherence check blocks on injected mismatch (AC-5 / FR-3 / DoD D5):** inject a deliberate
  requirement-orphan (a REQUIREMENTS term with no seed concept) and confirm BOTH layers execute, the
  mismatch is surfaced as an NFR-7 question, progress is BLOCKED until resolved, and the check re-runs
  clean after the seed is amended.
- **(D) Brownfield intact (NFR-2 / AC-10 / DoD D6):** the `kb-freshness-check.sh` / `lint-frontmatter.sh`
  / `build-kb-index.sh` existing suites and task-021's marker suite pass; the brownfield review path
  (`greenfield: false`/absent) is byte-unchanged (diff the default-render of `document-expectations.md` /
  `reviewer-brief.md` / `state-review.md`); the existing aid-interview brownfield/lite path is unaffected.
- **(E) §6 master-only heavy gates:** run `tests/run-all.sh` (HOME-pinned) and the `site` Astro build
  locally; both green.
- Record results to this task's STATE.md / the delivery gate; file any [HIGH]/[CRITICAL] findings per the
  ledger schema. Out of scope: fixing content defects (loop back to the owning task 019-025).

**Acceptance Criteria:**
- [ ] A code-less project yields a forward-authored seed that passes the greenfield-mode review gate at the work minimum grade (A+, TOTAL 0) -- full panel, as-built red flags relaxed, intent-evidence accepted. *(AC-2/NFR-3, DoD D3; gate criterion 1)*
- [ ] A downstream `aid-specify` run on the approved seed completes with ZERO KB-gap loopbacks, and the as-built exclusion docs are absent (minimal-but-sufficient). *(AC-2/RQ-A5, DoD D4; gate criterion 1/4)*
- [ ] An injected requirement-orphan is surfaced by the coherence check as an NFR-7 question, BLOCKS progress until resolved, and the check re-runs clean after amendment; both layers execute. *(AC-5/FR-3, DoD D5; gate criterion 3)*
- [ ] Brownfield intact: the three KB-script suites + task-021's marker suite pass, and the brownfield review path (`greenfield: false`/absent) + aid-interview brownfield/lite path are byte-unchanged (verify via diff). *(NFR-2/AC-10, DoD D6; gate criterion 2)*
- [ ] Master-only heavy gates pass locally: `tests/run-all.sh` (HOME-pinned) and the `site` Astro build. *(gate criterion 5)*
- [ ] Tests are deterministic with clean setup/teardown; all delivery-004 gate criteria and the feature-003 ACs (AC-2/AC-5) + DoD D1-D6 are covered. *(TEST defaults)*
