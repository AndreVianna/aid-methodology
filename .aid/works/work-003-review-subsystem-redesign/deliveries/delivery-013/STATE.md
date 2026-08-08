---
delivery_state: Gated
gate_tier: Medium
gate_grade: "Pending"
gate_timestamp: "--"
ticket_ref: "--"
---

# Delivery State -- delivery-013

<!-- ZONES
  FRONTMATTER (single writer = this delivery's branch): delivery_state, gate_tier,
      gate_grade, gate_timestamp, ticket_ref.
  AUTHORED (single writer = this delivery's branch): the narrative remainder of
      Delivery Lifecycle / Delivery Gate, and Cross-phase Q&A.
  DERIVED (read-only, assembled at read time): Tasks State.
  Identifiers (Delivery / Work / Branch) are INFERRED from the folder name and git
  worktree -- never authored in frontmatter.

  Lifecycle enum: Pending-Spec | Specified | Executing | Gated | Done | Blocked
  Authored independently across the pipeline, NOT derived from task rollup:
    aid-plan    creates this file at Pending-Spec
    aid-specify advances to Specified
    aid-execute advances Specified -> Executing -> Gated -> Done, or to Blocked
-->

> **Delivery:** delivery-013
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-013

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch. The State scalar lives in the
     frontmatter above (delivery_state). -->

- **Updated:** 2026-07-28T17:26:52Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

<!-- AUTHORED -- single writer: the delivery-gate closing step of aid-execute on this
     delivery's branch. Reviewer Tier / Grade / Timestamp live in the frontmatter above. -->

- **Issue List:** gate DISPATCHED 2026-07-31 against today's HEAD, not the commit this delivery
  shipped at. This delivery was marked `Gated` with no gate record of any kind -- no grade, no
  timestamp, no issue list; see work `STATE.md` Q22. Reviewing it late is strictly stronger than
  reviewing it then: a criterion that held at ship time and has since been broken is a finding the
  original gate could not have produced.
- **Cycle 1 (2026-07-31):** 13 rows -- 8 `[HIGH]` + 5 `[MEDIUM]`, one of which (row 3) the reviewer
  itself marked `Invalid`, superseded by row 4. Ledger:
  `.aid/.temp/review-pending/execute-delivery-013.md`.
- **Cycle 1 FIX (2026-08-08):** all 12 live rows `Fixed`. Six were `lint-modality.sh` mis-reading its
  own input; two were assertions that could not fail; five were the modality contract being declared
  in one place and unenforced or unsupported in another.
  **The vacuity fix immediately earned itself.** Row 1 made a `--root` sweep that inspects zero rows
  exit 2 instead of printing "OK ... all carry a valid modality". Pointed at this work's own
  `features/`, it exited 2 over eight SPEC files -- which is row 10, found by the row-1 fix rather
  than by a reviewer. The old MG20 had passed over exactly that tree, because the SPECs' criteria were
  `- [ ]` checklists that the lint's `| AC-N |` matcher cannot see: the gate criterion "no untagged
  criterion in the tree" was satisfied by unreadability, not by tagging.
  **Rows 11-13 are one root cause.** `aid-describe` copies `templates/requirements.md`, which carried
  bare section headers and no tables at all -- while the sibling `requirements/requirements-template.md`
  that the suite tests carried the Modality column. And `templates/feature.md` wrote acceptance
  criteria as a checklist, so no SPEC written to the shipped template could ever produce exit 1, which
  is why `aid-specify`'s gate block certified a property it had no way to observe. Both templates now
  carry the table; `aid-define` gained a Step 4b that gates the decomposition output, which nothing did
  before.
  **Row 10's back-fill carries modality, it does not invent it.** 23 criteria rows added across 8
  feature SPECs: features 001-006 and 008 take theirs from `REQUIREMENTS.md § 9` unchanged, and
  feature-007 -- which owns none of the numbered criteria -- synthesises from group F with each row
  inheriting the modality of the requirement it discharges and a `Discharges` column recording which.
  Tree sweep now reads **95 rows** where it read 70: +23 criteria, +2 from row 2's split-ID fix.
  **Two things the back-fill surfaced that no row named:** `AC-13` was owned by no feature SPEC at all
  (delivery-001 measures its baseline and feature-006 owns its siblings -- now listed there), and
  `FR-F6` has no acceptance criterion anywhere (implemented and covered by
  `test-one-grading-backend.sh`, but never written as a criterion -- recorded in feature-007's SPEC
  rather than invented). Also fixed: delivery-001's BLUEPRINT called `AC-13` "a MUST" where § 9 says
  `SHOULD`; swept the class, that was the only real instance.
- **Verification:** `lint-modality --root` over the work tree 95/95 -- `modality-gate` 24/24 with four
  mutations individually proved -- `shortcut-engine-contract` 15/15, its new `SEC04c`/`SEC04d` proved
  by reverting the delegate to the flat breaker -- `criteria-gaps` 35/35 -- `byte-identity` 755/755
  after render + dogfood resync. `test-multitool-isolation.sh` times out locally (it builds fixture
  tarballs and runs three installs); its T13-T20 constraint on `templates/requirements.md` was checked
  directly instead -- byte-identical across all five profiles, so the added comment introduced no
  tool-specific path.
- **State:** the FIX is complete and ungraded until a fresh reviewer runs.

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of
     aid-execute). Written here, NOT into the shared work-level STATE.md, to preserve the
     disjoint-write property. -->

_None yet._

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEW
     Assembled at READ TIME from tasks/task-NNN/STATE.md. Never written here.
     ============================================================ -->

## Tasks State

<!-- DERIVED -- read-only rollup from tasks/task-NNN/STATE.md.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
