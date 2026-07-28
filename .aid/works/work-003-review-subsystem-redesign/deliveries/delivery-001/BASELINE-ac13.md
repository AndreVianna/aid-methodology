# AC-13 cost baseline -- captured at delivery-001, 2026-07-28

Pre-migration review cost, captured before any review-path edit.

---

## The instrument does not exist yet

AC-13 was written on the premise that the `## Dispatch Log` (per task) and `## Calibration Log` /
`## Dispatches` (per work) sections carry **always-on** telemetry -- *"appended by the dispatcher on
subagent completion (L1+L2+L3 traceability; always-on, never optional). One row per dispatch."*

**That is what the templates say. It is not what happens.** Verified at delivery-001: every one of
those sections in this work contains a header row and nothing else. Across the entire Describe →
Detail pipeline -- 49 sub-agent dispatches -- **zero rows were written**.

So two of AC-13's three required numbers are **unrecoverable retrospectively**:

| AC-13 number | Recoverable? | Source |
|---|---|---|
| Total dispatch count | **Yes** | Session record, enumerated below |
| FIX-cycle count | **Yes** | `## Features State` cycle notes, enumerated below |
| Per-dispatch agent **and tier** | **No** | The log is empty, and no model was pinned per dispatch |

**Consequence, and it is a real gap I introduced:** AC-13 cannot be satisfied as written until
something actually populates the Dispatch Log. I authored AC-13 on the assumption that documented
machinery was live -- the same failure as the retracted emission-manifest claim: trusting a
document's description of a mechanism instead of checking whether the mechanism runs. Populating
the log is now a **prerequisite of AC-13**, not an input to it. See the amendment note in
REQUIREMENTS.md.

---

## What is recoverable: the pre-migration baseline

Counted from the session record. Every number here is a dispatch I made or a cycle recorded in
`STATE.md ## Features State`.

### Per-artifact gate passages (Specify phase)

| Artifact | Architect dispatches | Reviewer dispatches (cycles) | FIX cycles |
|---|---|---|---|
| feature-001 | 1 | 4 | 3 |
| feature-002 | 1 | 3 | 2 |
| feature-003 | 1 | 3 | 2 |
| feature-004 | 1 | 3 | 2 |
| feature-005 | 1 | **2** | 1 |
| feature-006 | 1 | 3 | 2 |
| feature-007 | 1 | 6 | 5 |
| feature-008 | 1 | **9** | 8 |
| **subtotal** | **8** | **33** | **25** |

### Phase gates

| Gate | Architect | Reviewer | FIX cycles |
|---|---|---|---|
| Plan | 1 | 3 | 2 |
| Detail | 1 | 3 | 2 |
| **subtotal** | **2** | **6** | **4** |

### Totals

- **Total sub-agent dispatches: 49** (10 architect + 39 reviewer)
- **Total FIX cycles: 29**
- **Cheapest single gate passage: feature-005** -- 1 architect + 2 reviewer = 3 dispatches, 1 FIX cycle
- **Most expensive: feature-008** -- 1 architect + 9 reviewer = 10 dispatches, 8 FIX cycles

### The nominated fixture

**feature-005's Specify gate passage** is the fixture for the AC-13 comparison: 3 dispatches, 1 FIX
cycle, one artifact, cleanly bounded. It is the *best case* under the current pipeline, which makes
it the honest comparator -- beating a worst case would prove nothing.

---

## What this baseline can and cannot support

**Can support:** a post-migration comparison on **dispatch count** and **FIX-cycle count** for an
equivalent artifact. Both are counted the same way before and after, so the comparison is valid.

**Cannot support:** the **tier-weighted** cost AC-13 asks for. No tier was recorded, and no
weighting was ever defined. Two options, and the choice belongs to whoever implements AC-13:

1. **Populate the Dispatch Log first** (agent + tier per dispatch), then measure post-migration
   against a *re-run* of the fixture with logging on. Correct, and costs one extra fixture run.
2. **Drop the tier weighting** and compare dispatch count and FIX cycles only. Cheaper, and still
   catches the failure mode that matters -- a split that adds dispatches without removing cycles.

**Recommendation: option 2**, plus populating the log going forward. The tier weighting was
speculative precision; the count comparison is what actually tests whether the split saved
anything.

---

## Honest limits

- The dispatch counts are **authoring-phase** costs (Specify/Plan/Detail), not Execute-phase task
  reviews. The migration changes both, but only the authoring side is measured here.
- Cycle counts conflate "the reviewer found something" with "the finding was worth finding". Across
  the 29 FIX cycles, essentially every finding was a citation or count defect -- which is why
  feature-008 exists and why its own gate cost 8 FIX cycles.
- No elapsed time was recorded, so nothing here supports a wall-clock claim.
