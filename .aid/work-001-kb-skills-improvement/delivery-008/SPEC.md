# Delivery SPEC -- delivery-008: Skill Topology + Ship

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md. It is the IMMUTABLE DEFINITION for this delivery.
Written by aid-plan; not a state file. State lives in delivery-008/STATE.md.

> **Delivery:** delivery-008
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23

---

## Objective

Fill the skill-topology gaps in the KB lifecycle, AND ship the change in lockstep across the whole
canonical->render machinery. Rename `aid-ask` -> `aid-query-kb` (read side; behavior preserved);
add a new `aid-update-kb` skill for targeted/punctual KB updates -- the "second pass" for the
precise deltas a finished work introduced -- applied through the **same review/calibration gate as
`aid-discover`** by consuming delivery-001's f005 injectable ledger-`<scope>` + doc-set seam; and
make `aid-query-kb` capture gaps ("KB can't answer" / "KB contradicts code") into a KB-gap queue
consumed by `aid-update-kb` / `aid-housekeep`. Then propagate: render the changed/new skill into all
five host trees with render-drift green, orphan-prune the retired `aid-ask` content by prefix,
keep the five install manifests in lockstep, reconcile the ~10 KB-doc "N user-facing skills" count
references, and update the docs site.

## Scope

In scope -- **feature-008 (author/behavior) + feature-009 (ship/propagation) as ONE delivery**:

- **feature-008:** the `aid-ask` -> `aid-query-kb` rename (canonical source); the new
  `aid-update-kb` thin-router SKILL.md + state machine (reusing f005's review gate via the injectable
  scope+doc-set seam); query-side gap-capture into the `STATE.md ## Q&A (Pending)` backlog.
- **feature-009:** running the full generator to render `canonical/skills/` into all 5 host trees;
  orphan-pruning the retired rendered `aid-ask/` dirs by prefix; re-bundling the 5 install manifests
  in lockstep; reconciling the ~10 "N user-facing skills" KB-doc count references; updating the docs
  site.

**Out of scope:** f005's panel + injectable-scope seam itself (delivery-001 -- consumed as final);
the housekeep<->update-kb non-overlap *contract* + standing closure (delivery-009, f010 -- this
delivery ships the `aid-update-kb` skill, delivery-009 draws its boundary vs `aid-housekeep`).

## Gate Criteria

- [ ] `aid-ask` has been renamed to `aid-query-kb` with behavior preserved. *(f008, AC8)*
- [ ] Given a prompt-driven targeted update, `aid-update-kb` applies it through the same
  review/calibration gate as `aid-discover` (via f005's injectable scope+doc-set seam). *(f008, AC8)*
- [ ] Given a query the KB cannot answer (or that contradicts code), `aid-query-kb` enqueues a gap
  into the KB-gap queue consumed by `aid-update-kb` / `aid-housekeep`. *(f008, AC8)*
- [ ] The full generator renders the changed/new skill into all five host trees with render-drift CI
  green; the retired `aid-ask` content is orphan-pruned by prefix; the five install manifests are
  updated in lockstep. *(f009, AC12)*
- [ ] The ~10 KB-doc "N user-facing skills" count references and the docs site are reconciled; the
  rename/add lands as **one branch/PR with no intervening release tag**; KB-hygiene CI passes. *(f009, AC12)*
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001, delivery-007
- **Blocks:** delivery-009

## Notes

**f008 + f009 are inseparable (Cross-Cutting Risk R2):** ONE branch, ONE PR, **no release tag cut
between them**. render-drift CI is RED on f008 alone (canonical renamed but host trees not
re-rendered) and green only once f009 propagates; a release between them would ship a half-renamed
repo. Consumes delivery-001's f005 injectable ledger-`<scope>` + doc-set seam (the `aid-update-kb`
review gate) and delivery-007's per-doc freshness as part of the lifecycle the topology completes.
The "adding a skill -> KB count drift" and "render-drift full generator" hazards both apply here --
run the FULL generator, reconcile counts (precedent: /aid-housekeep Q26/Q27), keep the 5 manifests
lockstep on the skill file set.
