---
state: Done
review: "Pending"
elapsed: "--"
notes: 'Both coverage ratios retired; gates keyed on the Rule enum scoped by mandate prefix; visual gate split three ways with --non-functional reserved for nothing-usable. AC-2 closed for the act-back gate and the Divergence half; the Omission half stays on the [ESSENCE-GAP] marker per human decision, logged as Declined gap kb-essence/load-bearing-fact-coverage. 3 [HIGH] quick-check findings, all fixed-on-spot.'
ticket_ref: "--"
---

# Task State -- task-004

<!-- The `## Task State` mutable cell (state/review/elapsed/notes) lives in the frontmatter above.
     This file is the SOLE write target for all per-task mutable state. Its parent
     `deliveries/delivery-NNN/STATE.md ## Tasks State` and the work-level `## Tasks State` are
     DERIVED read-only views assembled from this file at read time -- never written directly.
     task/delivery/work identifiers below are INFERRED from the folder path. -->

> **Task:** task-004
> **Delivery:** delivery-015
> **Work:** work-003-review-subsystem-redesign

---

## Task State

<!-- AUTHORED -- values live in the frontmatter above, written ONLY by
     `writeback-state.sh --task-id 004 --field State --value VALUE`.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
     Ordering (most-advanced wins on reconcile):
       Done > Canceled > In Review > In Progress > Blocked > Failed > Pending
     MANDATORY: `state` MUST be written the INSTANT it changes. -->

---

## Quick Check Findings

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:**
  - [HIGH] The teachback prompt's own example row told the M3 reviewer to write `Rule = KB-20` on a `[FIDELITY]` Divergence row, contradicting the derivation this task had just re-pointed at `Rule == NAR-05`. An agent copies the example, so the gate would have counted zero Divergences -- canonical/skills/aid-discover/references/reviewer-prompt-teachback.md:193 -- Fixed-on-spot (now `NAR-05`; all 11 example rows across the four mandate prompts re-verified to cite a real catalog ID)
  - [HIGH] Found while checking the above: keying the gates on `Rule` alone leaks findings across them. `NAR-05` and `KB-20`..`KB-26` are legitimately available to the correctness and anatomy mandates, and an M3 Omission row must itself carry a `KB-2x` ID (the schema states "There is no exemption" for a finding row), so one omitted fact would have failed the assertiveness verdict with no act-back finding behind it -- canonical/skills/aid-discover/references/state-review.md:286,355 -- Fixed-on-spot (both gates now scoped by the existing per-mandate `#` prefix, `TB-` and `AB-`; prose, summary table and pseudo-code all agree)
  - [HIGH] The correctness prompt still instructed reviewers to put `KB-20` in `Rule` as a placeholder "because the KB rule set does not yet assign rule IDs". It has assigned them since 2026-07-29, and as of this task the column feeds a gate -- so a stand-in ID stopped being inert text and became a wrong gate input -- canonical/skills/aid-discover/references/reviewer-prompt-correctness.md:116 -- Fixed-on-spot (points at the real catalog; example row now `NAR-05`)
- **Note:** the reviewer also proposed setting the Omission row's `Rule` to `--`. Verified wrong and not applied: `reviewer-ledger-schema.md § Rule values` states "There is no exemption" for a finding row and `writeback-ledger.sh` refuses such a row with exit 4. Checking it is what surfaced the leak above.
---

## Dispatch Log

<!-- AUTHORED -- appended by the dispatcher on subagent completion. One row per dispatch. The
     work-level ## Calibration Log and ## Dispatches views are DERIVED unions of these sections. -->

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
