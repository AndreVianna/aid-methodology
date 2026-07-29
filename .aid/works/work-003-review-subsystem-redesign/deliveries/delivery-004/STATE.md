---
delivery_state: Done
gate_tier: Medium
gate_grade: "A+"
gate_timestamp: "2026-07-29T03:20:00Z"
ticket_ref: "--"
---

# Delivery State -- delivery-004

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

> **Delivery:** delivery-004
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-004

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch. The State scalar lives in the
     frontmatter above (delivery_state). -->

- **Updated:** 2026-07-29T03:20:00Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

<!-- AUTHORED -- single writer: the delivery-gate closing step of aid-execute on this
     delivery's branch. Reviewer Tier / Grade / Timestamp live in the frontmatter above. -->

- **Issue List:** 12 rows, `.aid/.temp/review-pending/delivery-004.md` — 10 `Fixed`, 2 `Accepted`,
  0 `Pending`. Severities as found: 1 `[CRITICAL]`, 3 `[HIGH]`, 6 `[MEDIUM]`, 2 `[LOW]`.
- **Result:** the catalog ships as `review-rubrics/` — `INDEX.md` (universal tier: rule-row schema,
  ID format, defect taxonomy, five review kinds, two authority ladders, six families, routing table
  plus its resolution procedure), six family rule sets, and two class files (`summary.md`, `aid.md`).
  **58 rule rows**, every one carrying a `Criterion` that resolves to a file that exists and a
  heading that is greppable. Severity is now a lookup against the violated rule's anchor.

### Three vacuous assertions, all caught by negative control

The delivery's most important finding is about its own test suite. `RR11`/`RR12` — the two
assertions the entire catalog rests on — **passed on deliberately broken citations**. A `Criterion`
is written `` `doc.md § Section` ``, one backtick pair wrapping both; the parser required a closing
backtick straight after `.md`, matched nothing, and reported success. `RR20` failed the same way
later for a different reason: routing rows end with a trailing `|`, so `$NF` was the empty field and
every row was skipped.

A test that inspects nothing is worse than no test, because it manufactures confidence. Three
guards now exist so this cannot recur silently: `RR16`, `RR17` and `RR21` fail if their checker
inspects fewer than a floor number of items, and `.aid/.temp/vacuity2.py` breaks a document name and
a section name and asserts the suite goes red for each. **Every future assertion added here should
get a negative control before it is trusted.**

### Findings that came from writing the catalog rather than reviewing it

- **I authored three citations to KB sections that do not exist** (`§ Phase Contracts`,
  `§ Durable citations`, `§ Document Structure`). Authoring against remembered headings rather than
  `grep`-verified ones reproduced, inside this very feature, the defect class feature-008 exists to
  prevent.
- **`schemas.md` does not exist.** feature-002's SPEC §3 names it as the `DATA` class's manner
  authority; the KB spine has `artifact-schemas.md`. Corrected here with an inline note so it is not
  re-propagated. **The SPEC is wrong and should be amended.**
- **The routing table did not actually route.** It lists ~12 selectors while the families span far
  more classes, so `RESEARCH`, `API`, `TICKET` and others resolved to nothing. Family fallback was
  described as a concept but never as a procedure. Fixed with an ordered three-step resolution
  (exact route → family fallback → criteria gap), first match wins.
- **`RR23` caught two rows marked `mechanical` whose Evidence named a procedure, not a command.**
  `DEF-05` gained a real `grep`/`diff` form; `INT-01` was retyped to `judgment`, because diffing an
  arbitrary published contract is not a single command. The assertion was kept strict rather than
  loosened to accept the prose.

### Deliberate gaps, recorded so they are not read as omissions

Interface ships without versioning/deprecation rules, Presentation without responsive-behaviour or
state-coverage rules, Process without ticket-workflow rules. No declaring document exists for any of
them, and under the admission rule — **no `Criterion`, no row** — inventing them is precisely what
this work removes. Each file states the gap so a reviewer raises it instead of filling it in.

### Suite performance, and what the full run does and does not prove

The catalog suite first ran **222s** on Windows/Git Bash (~400 process spawns, several pipelines per
row) against `run-all.sh`'s 300s per-suite timeout. Collapsed to two bulk passes: **7.2s**, same
assertions, controls re-verified afterwards.

`tests/run-all.sh` reports **28 of 134 canonical suites failing, and `test-review-rubrics.sh` is not
among them.** An earlier run listed it, but that run raced my own editing — it executed the suite at
a moment when `RR22`/`RR23` existed while the awk still emitted 7 fields, so `Check` and `Evidence`
read empty for every row.

**The 28 are not attributed to this delivery, on four pieces of evidence** — not on assumption:

1. Two consecutive runs over identical content produced **27 then 28** failures with **different
   sets**, which is harness flakiness, not content.
2. `review-rubrics` appears **5 times in 3086 log lines**, none of them in another suite's failure.
3. Both `lib/` edits are **comment-only** (`git diff` confirms four changed lines, all `#`), so they
   cannot reach installer or CLI behaviour.
4. A baseline probe (stash the delivery, re-run the failing set) confirmed `test-aid-cli-parity` and
   `test-aid-cli-ps1` **fail without this delivery present**.

**The probe was aborted after 2 of 28 suites**, because serial installer suites were running at
~6 min each (≈3 h projected). So the pre-existing status of the remaining 26 is **argued, not
measured** — a genuine residual weakness in this gate. The suites are dominated by
dashboard/installer/release/PowerShell lanes needing servers, registries and network. **A recorded
red baseline for this repo on Windows would remove the need to re-argue this every delivery, and is
worth its own task.**

### Render, regions, and the dogfood hop

All 9 catalog files render to **all five profiles** at `<install-root>/aid/templates/review-rubrics/`
— correctly nested, which is what the catalog's own `AID-01` requires of AID-delivered content.
`rewrite_install_paths` resolves the backticked `canonical/...` pointers per profile while leaving the
relative markdown link targets intact. The deterministic hard gate (byte-identical re-render,
file-presence audit, frontmatter parse) passed on two consecutive runs, the second after the
`DEF-05`/`INT-01` fixes.

Per delivery-003's standing note, the generator writes `profiles/*` **only**, so this repo's own
`.claude/` and `.cursor/` installs were synced by hand — 9 catalog files each plus the rebuilt
`aid-reviewer` body. Without that hop the repo dogfoods a stale catalog.

`git diff` on `aid-reviewer/AGENT.md` touches exactly three declared regions: the `description:`
frontmatter, the two source-tag bullets, and the `Standing KB-Convention Checks` deletion. **Lines 75
and 96-99 are claimed by feature-002 but left untouched on purpose** — both describe the *seven*-column
ledger, and the eighth column belongs to delivery-005, which this BLUEPRINT puts out of scope.
Touching them here would land a column the schema does not yet define.

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
