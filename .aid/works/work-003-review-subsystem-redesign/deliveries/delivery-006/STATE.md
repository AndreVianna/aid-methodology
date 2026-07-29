---
delivery_state: Done
gate_tier: Medium
gate_grade: "A+"
gate_timestamp: "2026-07-29T05:20:00Z"
ticket_ref: "--"
---

# Delivery State -- delivery-006

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

> **Delivery:** delivery-006
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-006

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

- **Issue List:** 7 findings + 1 gap + 5 coverage rows, `.aid/.temp/review-pending/delivery-006.md` —
  all 7 findings `Fixed`, 0 `Pending`. Severities as found: 2 `[HIGH]`, 3 `[MEDIUM]`, 2 `[LOW]`.
- **The ledger was written entirely by the helper this delivery ships** — one
  `writeback-ledger.sh` call per row, no heredoc, all three row kinds in one real file. That is the
  end-to-end proof, and it is worth more than the fixtures.

### I committed the exact defect I refused to commit one delivery ago

Delivery-005 declined to write `KB-26` into an example because the KB rule set defines no IDs, and
recorded the dependency instead. Then this delivery's schema wrote **`KB-22`** into its worked rows and
its usage example. Same fabrication, one delivery later, by the same author who had just written the
paragraph explaining why not to.

`EC21` caught it — the assertion added *in delivery-005 for exactly this*. That is the argument for
mechanical checks over remembered intentions, made at my own expense: knowing the rule, having just
written it down, and stating it in a gate record was not enough. The assertion was.

Replaced with `NAR-04`, which actually describes the example row (a stale count claim).

### Two logic bugs the smoke test found before the suite existed

- **`--set-status` emitted a doubled leading pipe** (`|| U-001 |`), which then made the row unfindable,
  so a successful write was followed by a failing `--get-status`. The awk loop already emits a leading
  pipe; prefixing another duplicated it. Found by running the thing by hand and *reading the output
  table*, not by any assertion.
- **The rule-set digest resolved the catalog one directory too high**, so every `rs=` read `absent`.
  The script sits at `aid/scripts/review/` and the catalog at `aid/templates/` — `../..`, not `..`.
  Found only because the smoke test used a real file instead of a fixture name; with `foo.md` the
  digest is legitimately `absent` and the bug is invisible.

Both argue the same thing: **run it on real inputs before writing assertions about it.**

### The test suite needed correcting more than the script did

Three of the seven findings are against my own tests:

- **`WL14` counted changed LINES**, so a bug clobbering another cell of the *same* row was
  undetectable. A negative control clobbered cell 8 on the target row and the suite stayed green.
  `WL15` now compares the target row **cell by cell** and requires exactly one difference, at Status.
- **`WL26` compared `grade.sh` output to itself** — `assert_eq "$(g $L)" "$(g $L)"`, true for any
  input. Now compares a pipe-bearing ledger against the pipe-free equivalent.
- **`EC18` flagged the helper's own NFR-5 handling** as a stale 7-column claim. The helper *must*
  recognise a 7-column header to refuse `--rule` against it. Excluded by name with the reason stated,
  next to the schema exclusion that already existed.

Five negative controls were run against the new suite; two came back VACUOUS. One of those was a
**broken control** (neutering the first AC-3 guard left two more that fired anyway — layered defence,
working). The other was a **real gap**, and is finding 5 above. Both re-run and CAUGHT after fixing.

### A criteria gap I recorded rather than forced into a rule

Two findings are plain logic bugs in a shell script, and the Executable family has **no rule for
"code produces output violating a declared format contract"** — it covers build, lint, test,
conventions, contracts and boundaries, but not an output-shape defect. I used `EXE-06` (output goes to
the declared stream) as the closest fit and logged **`G-001`** for the real gap, with a resolution
naming two options. Under the admission rule the honest move is to record the gap, not to stretch a
rule until it covers everything.

That the very first real use of the gap mechanism found a gap in the catalog shipped two deliveries
earlier is the improvement loop working as designed.

### AC-9, proved on a real ledger

Adding five coverage rows and one gap row to a ledger with seven findings left both the grade and the
`--explain` breakdown unchanged. Not a fixture — the delivery's own ledger, graded `A+` with all
counts zero, the `U-` and `G-` rows invisible to the grader because a `--` in Severity fails the
match chain before Status is ever read.

The helper **verifies this at write time by default**: it grades the pre-image and the post-image on
every non-finding write and refuses the write if they differ. AC-9 is enforced continuously, not
only in a test.

### The new script directory, confirmed by rendering

The BLUEPRINT insisted this not be assumed, and it was right to: the `aid/scripts/` mapping is
directory-level, but a brand-new `review/` child had never exercised it. Confirmed the strong way —
the helper reached **all five profiles** at the correctly nested path, appears in **all five emission
manifests**, kept its executable bit (`-rwxr-xr-x`), and the **rendered copy runs**, resolving
`grade.sh` two directories up and the rule catalog three. Relative paths with no `canonical/` prefix
are why that works identically in canonical and in every profile.

### Result

- `writeback-ledger.sh`: five modes, script-assigned IDs, sentinel lock, CRLF and trailing-newline
  invariance, pipe escaping, newline rejection, post-write sanity checks with the original preserved
  on any failure, and eight documented exit codes.
- **AC-3 is mechanical at last.** A finding with no rule ID is refused with exit 4 — three layered
  guards, all three proved necessary by control. The one exemption (a `Status: OOS` row may carry
  `--`) is upstream-forced, not invented here.
- **Zero heredoc ledger writes survive**: `LEDGEREOF` and `cat > …review-pending` both return nothing
  across `canonical/`, the KB and the root agent files.
- `aid-discover`'s merge rule now **excludes `U-` and `G-` rows from the panel merge** — they are
  per-writer bookkeeping, and merging them would imply one coverage frontier where there is one per
  mandate. Gaps still reach the orchestrator, as an escalation rather than a merged row.
- Suites: `test-writeback-ledger.sh` **43/43**, `test-ledger-eighth-column.sh` **23/23**,
  `test-review-rubrics.sh` 28/28, and the two NFR-5 fixture suites unchanged and green.

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
