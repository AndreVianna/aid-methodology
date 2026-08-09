# Delivery BLUEPRINT -- delivery-017: Quote check and citation wiring

> **Delivery:** delivery-017
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Add the attributed-quote check and wire the citation lint where authoring happens, so a citation
defect is caught before a reviewer is dispatched rather than after a review cycle is paid for.

## Scope

- The attributed-quote check, **re-dispositioned 2026-08-09 (`Q25`) as a cheap PRE-FILTER, not a
  gate.** The criterion for a quote is **semantic fidelity** -- the content must mean exactly what
  the source intends -- and formatting, spacing, emphasis and exact wording are irrelevant. A
  literal substring test cannot express that: a faithful reword fails it and a byte-perfect quote
  that inverts the source's meaning passes it, and **both directions are wrong**. So: a substring
  **hit proves fidelity and exits early**; a **miss escalates to reviewer judgment rather than
  failing**, because a miss means only *not byte-identical*, which under the meaning criterion
  proves nothing. Emphasis normalisation stays but is **demoted** -- it widens the pre-filter's hit
  rate and is no longer load-bearing, since a normalisation miss no longer decides anything. The
  precedent is in this feature's own SPEC: `FR-G4` is already dispositioned *"a review rule, not a
  lint check"* for the same reason, and meaning is less mechanically reachable than counting.
- The `aid-deep-review` RESOLVE gate: one site, covering every caller that invokes
  `/aid-deep-review` -- `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute`'s
  delivery gate, `aid-discover` and the shortcut engine's GATE, plus `aid-describe` and
  `aid-update-kb`, which reach it through `aid-discover`'s panel. **Not** any review that dispatches
  `aid-reviewer` directly -- `aid-review` / `aid-audit`, whose Tier-2 migration feature-006 planned
  and delivery-012 scoped out; `aid-specify`'s per-section review; `aid-execute`'s Step 1.5;
  `aid-discover`'s FIX-state re-review; and the Tier-3 dispatches feature-006 deferred. This
  delivery gates none of them, and the residual set is derived at implementation time rather than
  counted here.
- The CI step: no workflow references the citation lint today, so this delivery adds it. (The KB claim that it already ran was corrected by delivery-002.)
- The gate rows in `quality-gates.md`, and the durable-citation convention in the authoring
  principles -- including that a quote which must survive the check should be a short fragment from
  a single source line. **That guidance survives with its rationale rewritten (`Q25`):** it is no
  longer a rule for passing a gate, but advice for making the *cheap path* succeed, so that fewer
  quotes escalate to judgment.
- A judgment rule for the escalated case -- the quote that misses the pre-filter and must be judged
  on meaning. `FR-G4`'s disposition is the precedent for declaring one without inventing a criterion.
- FR-G4's count-claim rule row in the Definition family file.
- **The `AC-14` and `FR-G3` amendments themselves** (`Q25`). This delivery is their carrier: the
  re-disposition changes what those two statements require, and no other delivery is scoped to
  touch them. Also the two task `DETAIL.md` files under this delivery that assert the retired
  byte criterion -- they are re-detailed, not patched around.

**Out of scope:** the count-claim re-runner; the table-cell and unattributed-prose citation forms,
which no regex reaches and which the deep reviewer covers instead.

## Gate Criteria

- [ ] A quote present in its source passes and exits early; one differing only in markdown emphasis
      also passes -- the second is the assertion that keeps the cheap path worth having
- [ ] **A quote absent from its source does NOT fail the run.** It escalates to reviewer judgment,
      because a miss means only *not byte-identical* and the criterion is meaning (`Q25`). A suite
      asserting that a missing quote fails would re-enforce the byte criterion this delivery retires
- [ ] A faithful reword -- different words, same meaning -- reaches judgment and is **not** reported
      as a defect. The converse is deliberately **not** asserted here: a byte-perfect quote hits the
      pre-filter and exits early by criterion 1, so it never reaches judgment. A verbatim string
      that misleads through selective framing is a real defect, but it is invisible to this check
      and belongs to the deep reviewer -- claiming it here would be a criterion nothing can satisfy
- [ ] An unattributed quote is advisory and does not change the exit code, so the coverage boundary
      is reported rather than hidden
- [ ] The RESOLVE gate sits ahead of DISPATCH and blocks it on exit 1, and passes a corrected
      artifact through -- so every caller routed through `/aid-deep-review` is covered by the one site
- [ ] The citation lint runs in CI
- [ ] AC-14 **as amended** holds on fixtures in both directions: a faithful reword is accepted, and
      a citation whose file or line does not resolve is still rejected. The retired byte-identity
      reading is not asserted -- a fixture that fails only on wording is not a defect
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** delivery-002, delivery-004, delivery-012
- **Blocks:** delivery-022

## Notes

**Spine delivery.** It extends the script delivery-002 ships, hence the dependency on it. The
convention it lands is the one this work learned the hard way: a long verbatim quotation drifts on
every hand-edit, so quote short and paraphrase openly.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | The attributed-quote check |
| task-002 | CONFIGURE | 2 | RESOLVE gate and CI step |
| task-003 | DOCUMENT | 2 | Gate rows and the citation convention |
| task-004 | IMPLEMENT | 1 | The count-claim rule row |
