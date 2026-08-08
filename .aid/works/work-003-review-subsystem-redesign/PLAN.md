# Plan -- Review Subsystem Redesign

> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28
> **Deliveries:** 18 (re-cut from the 26 the eight feature SPECs recommend)

---

## The AGENT.md spine -- a named invariant

Six of the eight features claim regions in `canonical/agents/aid-reviewer/AGENT.md` **line by
line**, and the no-region-touched-twice property depends on them landing in order. That order is
this work's central sequencing constraint and is named here so Detail and Execute can cite it:

```
the spine:  003 -> 004 -> 005 -> 006 -> 007 -> 009 -> 011
```

Delivery **010** inserts the two `{{include:}}` tokens and is the only other writer of that file.

Three obligations follow, and each spine delivery carries them as gate criteria:

1. **Regions are restated as quoted strings, not line numbers.** Every SPEC's affected-artifact
   inventory is valid only against the pre-003 base and goes stale the moment 003 lands.
2. **A diff assertion at each spine gate:** the delivery's `git diff` on that file touches only its
   declared regions, and no line is changed twice -- **except the two declared collateral cases**
   (feature-002's 96-99, deleted by feature-003; feature-003's line-79 clause, deleted by
   feature-005).
3. **No new script.** The assertion is a diff check, not tooling.

**Standalone-functional vs enabling.** The methodology's "every delivery is an MVP" rule holds for
**15 of 18**. Three ship no user-visible capability on their own and are labelled **enabling**
rather than dressed up as MVPs: **001** (baseline and fix-first), **005** (the eighth column), and
**010** (the boilerplate split, whose success criterion is an *empty diff*).

---

## Deliverables

`Track` -- **spine** = on the AGENT.md serial chain; **free** = escapes it.

### delivery-001: Baseline and fix-first
- **What it delivers:** the AC-11 and AC-13 measurement baselines, captured before any edit; the
  `aid-reviewer/AGENT.md` working tree reconciled to the committed base; the stale emission
  manifests corrected.
- **Features:** feature-006 (D0), plus three Q3 prerequisites
- **Depends on:** --
- **Priority:** Must
- **Track:** free
- **Kind:** enabling

### delivery-002: Citation lint
- **What it delivers:** a working citation checker over work artifacts -- the en-dash tokenizer
  fix, `--profile resolvable`, `--depth`, the resolver with its `find` fallback, range and
  resolution checks, and the fix commit on all eight SPECs.
- **Features:** feature-008 (D1)
- **Depends on:** --
- **Priority:** Must
- **Track:** free
- **Kind:** standalone

### delivery-003: Severity single source
- **What it delivers:** one canonical severity scale; "established best practice" removed as a
  criterion source. AC-1, AC-2.
- **Features:** feature-001 (D1)
- **Depends on:** delivery-001
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-004: Rubric catalog
- **What it delivers:** the rubric catalog skeleton, the per-class rule sets, and the
  content-isolation relocation -- severity becomes a lookup rather than a judgment.
- **Features:** feature-002 (D1 + D2)
- **Depends on:** delivery-003
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-005: The eighth column
- **What it delivers:** the `Rule` column added to the ledger schema and migrated tree-wide, with
  five-profile render parity. AC-3's carrier.
- **Features:** feature-002 (D3)
- **Depends on:** delivery-004
- **Priority:** Must
- **Track:** spine
- **Kind:** enabling

### delivery-006: Ledger substrate
- **What it delivers:** `writeback-ledger.sh` and the schema and documentation migration --
  surgical row writes replace whole-file rewrites. AC-9.
- **Features:** feature-003 (D1 + D2)
- **Depends on:** delivery-005
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-007: Criteria-gap interrupt
- **What it delivers:** `check-gaps.sh`, `gap-register.sh`, the durable gap register, and the
  semantic edits that make "no rule to judge this by" an actionable outcome. AC-4, AC-5, AC-10.
- **Features:** feature-004 (D1 + D2)
- **Depends on:** delivery-006
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-008: Gap gate wiring
- **What it delivers:** no grade is computed while a criteria gap is open, enforced at all 18
  grade sites.
- **Features:** feature-004 (D3)
- **Depends on:** delivery-007
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-009: Review resume
- **What it delivers:** `plan-resume.sh`, the ledger lifecycle rewrite, the FR-D5 migration moving
  status reconciliation to the orchestrator, and the non-task review stop signal. AC-6, AC-7, AC-8.
- **Features:** feature-005 (D1-D4)
- **Depends on:** delivery-007
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-010: Boilerplate split and aid-screener
- **What it delivers:** `agent-discipline-boilerplate.md`, the nine include-token insertions, the
  new `aid-screener` agent, and the roster growth 9 -> 10 across 21 count assertions.
- **Features:** feature-006 (D1)
- **Depends on:** delivery-001
- **Priority:** Must
- **Track:** free
- **Kind:** enabling

### delivery-011: aid-reviewer rewrite
- **What it delivers:** the FR-A10 agent-body rewrite, the README corrections, and the nine-item
  verify-do-not-redo conformance check.
- **Features:** feature-006 (D4)
- **Depends on:** delivery-009, delivery-010
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-012: Review extraction
- **What it delivers:** `aid-light-review` and `aid-deep-review`, the shared brief template, the
  six shrunken briefs, and nine caller migrations. AC-11 (provisional), AC-12.
- **Features:** feature-006 (D2 + D3)
- **Depends on:** delivery-009, delivery-010
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-013: Modality enforcement
- **What it delivers:** `lint-modality.sh`, the four template updates, the four skill wiring sites,
  and the retroactive back-fill.
- **Features:** feature-001 (D2)
- **Depends on:** delivery-003
- **Priority:** Must
- **Track:** free
- **Kind:** standalone

### delivery-014: Settings and frontmatter gates
- **What it delivers:** `lint-settings.sh` gating the settings file; `lint-frontmatter.sh` wired as
  a runtime gate with the M2 hand-check subtraction. Re-certifies AC-11.
- **Features:** feature-007 (D1 + D2)
- **Depends on:** delivery-004, delivery-012
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-015: One grading backend
- **What it delivers:** the weighted-points model retired; `grade.sh` becomes the sole producer of
  a letter grade. NFR-7.
- **Features:** feature-007 (D4)
- **Depends on:** delivery-004, delivery-008
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-016: kb.html content pass
- **What it delivers:** an adversarial content review of the generated summary, alongside its
  existing machine validators and human checklist.
- **Features:** feature-007 (D5)
- **Depends on:** delivery-015, delivery-012
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-017: Quote check and citation wiring
- **What it delivers:** the attributed-quote check, the `aid-deep-review` RESOLVE gate, the CI step,
  and the `quality-gates.md` gate rows. AC-14.
- **Features:** feature-008 (D2)
- **Depends on:** delivery-002, delivery-004, delivery-012
- **Priority:** Must
- **Track:** spine
- **Kind:** standalone

### delivery-018: BLUEPRINT and specify-section reviews
- **What it delivers:** `BLUEPRINT.md` graded rather than merely read; the per-section specify
  review gains a ledger and a `grade.sh` call.
- **Features:** feature-007 (D3)
- **Depends on:** delivery-012
- **Priority:** Should
- **Track:** spine
- **Kind:** standalone
- **Note:** the work's only `Should`, placed last so every `Must` precedes it.

---

## Dependency graph

Edges as an adjacency list, which is unambiguous where ASCII art is not:

| Delivery | Depends on | Blocks |
|---|---|---|
| 001 | -- | 003, 010 |
| 002 | -- | 017 |
| 003 | 001 | 004, 013 |
| 004 | 003 | 005, 014, 015, 017 |
| 005 | 004 | 006 |
| 006 | 005 | 007 |
| 007 | 006 | 008, 009 |
| 008 | 007 | 015 |
| 009 | 007 | 011, 012 |
| 010 | 001 | 011, 012 |
| 011 | 009, 010 | -- |
| 012 | 009, 010 | 014, 016, 017, 018 |
| 013 | 003 | -- |
| 014 | 004, 012 | -- |
| 015 | 004, 008 | 016 |
| 016 | 012, 015 | -- |
| 017 | 002, 004, 012 | -- |
| 018 | 012 | -- |

Every edge runs from a lower number to a higher one, so the ordering is a valid topological sort.
**No cycles.**

**Free tracks -- work available while the spine is blocked:** delivery-002 (fully independent),
delivery-001 (nothing upstream), delivery-010 (needs 001 only), delivery-013 (needs 003 only). That
is **4 free** and **14 on the spine**; no grouping breaks the spine, because it is a property of one
file rather than of the grouping.

---

## Sequencing decisions

| Decision | Resolution |
|---|---|
| Group by feature or across features? | **By feature.** Cross-feature merging would internally re-serialize anyway, and it would break the 1:1 delivery-to-SPEC-oracle mapping -- the only mechanical verification this work has. Merged *within* features where a sub-delivery ships nothing alone: 26 -> 18. |
| Where does the citation lint go? | **Second, ahead of the severity work.** Its own spec: *"D1 depends on nothing and gates nothing."* Every finding across 33 review cycles was a citation or count defect, so catching them mechanically beats paying a review cycle each time. Its fix commit on the eight SPECs is the input every downstream DETAIL reads. |
| AC-11's provisional status | delivery-012 earns AC-11 **provisionally**; **delivery-014 re-certifies it**, per feature-007's amendment to feature-006. 014 cannot move earlier -- its M2 subtraction sits in a file 012 migrates -- so the re-measure is accepted. |
| Priority ordering | The work has one `Should` (the BLUEPRINT and specify-section reviews) and it is numbered **last**, so every `Must` precedes it. Nothing forces it earlier: it depends only on delivery-012. |
| Extra parallelism | **Declined.** Splitting the settings gate out of 014 would add a fourth free track at the cost of another delivery gate. Three free tracks judged sufficient. |
| The WSL gitdir bug | **Leaves this work**, per concern N4. Not review-path. |

---

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | Line-number inventories go stale the moment delivery-003 lands | H | Restate regions as quoted strings at Detail; per-delivery diff gate on `AGENT.md` |
| 2 | AC-12 (five-profile parity) is only checked at delivery-012, so render drift from ten earlier deliveries arrives as one undiagnosable failure (concern N3) | H | Re-run parity as a regression gate at **every** delivery close; 012 owns the criterion of record |
| 3 | One blocked spine delivery stalls the other thirteen | H | Content anchors make skip-and-return survivable; 002, 010 and 013 provide work while blocked |
| 4 | The AC-13 cost baseline is unrecoverable once editing starts | M | delivery-001 is first and is a hard gate -- nothing else begins until the fixture gate-passage is recorded |
| 5 | delivery-010's success criterion is an **empty diff**, so a behavioural regression could hide inside a zero-diff claim | M | Keep 010 as its own delivery, never bundled -- feature-006's own recommendation |

---

## Deferred

| Item | Reason | Revisit when |
|---|---|---|
| WSL `worktree-lifecycle.sh` gitdir bug | Not review-path (concern N4) | Re-triaged into a worktree-tooling work |
| The `OOS` authorization bypass | Deliberately deferred pending a decision | A decision is taken |
| `DOC` and `REL` artifact classes | No KB doc declares their criteria; adding them would mean authoring standards inside feature-002 | Those standards exist |
| Tier-3's `repurpose` VERIFY dispatches | Out of FR-A6's scope: they carry a dispatch but no brief template, and no ledger-grade-FIX loop | A successor work |
| FR-G4's count-claim re-runner | Executes strings from markdown -- a code-execution surface the security conventions do not address | The convention has adoption |
| Historical two-grade `kb.html` values | Re-deriving a letter for findings that were never itemised would be fabrication | Never |
