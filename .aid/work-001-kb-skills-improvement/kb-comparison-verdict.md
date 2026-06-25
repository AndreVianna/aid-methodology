# Judge's verdict — NEW KB+kb.html vs BASELINE (master) — 2026-06-25

Balancing 3 critics (advocate / adversary / neutral), each evidence-backed, plus my own
spot-verification of the sharpest claims. Comparison: NEW `.aid/knowledge/` (24 docs) +
`.aid/dashboard/kb.html` (168 KB) vs BASELINE `.aid/.temp/kb-baseline-compare/master/`
(21 docs + 3.4 MB kb.html).

## Headline

**The NEW set is a clear net improvement — adopt it.** It is more correct, clearer, cleaner, and
more conformant, and the new `kb.html` is an unambiguous across-the-board win. The one **real
cost** is a reduction in *finest-grained operational reference depth* in a few shrunk shared docs
(+ the dropped `host-tool-capabilities` matrix): the NEW is a **better map and onboarding product,
a slightly thinner deep-operations manual.** That cost is **recoverable by re-injection**, not by
reverting — the new structure is the right home.

## How the three critics held up (judge's calibration)

- **Advocate** — fair; conceded the real cons (dangling ref, content-isolation prune detail,
  release log). Verdict (NEW wins all 7) is right in *direction*, slightly generous on completeness.
- **Neutral** — most balanced; its **recency caveat is the key fairness frame**: the two sets
  describe *different codebase eras*, so much of NEW's correctness edge is currency, not authoring
  skill (OLD was correct for its time). Its "OLD wins on raw depth" is correct.
- **Adversary** — **most valuable**: it found the one axis the others softened (operational
  reference-depth loss in the *shared* docs, confirmed by ⅔ line-count reductions). BUT its
  flagship exhibit was **overstated** — I verified NEW `pipeline-contracts.md` keeps the
  writeback-state contract as "Contract D" (six modes + enum validation), so "contract gone, name
  only" is false. What truly thinned: exit codes, locking-retry, per-suite enumeration, the
  host-tool matrix.

## Calibrated per-dimension verdict

| Dimension | Winner | Confidence | Judge's calibrated reading |
|---|---|---|---|
| **Correctness** | **NEW** | high | NEW matches today's repo (13 skills, `aid-query-kb`/`aid-update-kb`, 5 tools); OLD shipped now-stale facts (12 skills, `aid-ask`, "51 recipes"). Caveat: largely *recency* — OLD was correct for its era. |
| **Completeness** | **SPLIT** | high | **Intent + breadth → NEW** (decisions/quality-gates/process-arch add the *why* + gates + routing). **Raw reference depth → OLD** (pipeline-contracts 803→249, schemas 887→294, test-landscape 906→311; exit codes/locking/per-suite enumeration/host-tool matrix thinned). |
| **Clarity** | **NEW** | high | Single-concern, concept-organized, dual-audience standard; OLD mixed concerns in oversized docs. |
| **Cleanliness** | **NEW** | high (−2 nits) | NEW sheds OLD's stale counts + process-ledger bloat. Defects: `infrastructure.md:191` dangling ref to deleted `release-tracking.md`; `process-architecture.md` ↔ `workflow-map.md` duplicate the 13-skill phase table (drift risk). |
| **Conformity** | **NEW** | high | Uniform frontmatter→Contents→content→Change-Log, durable anchors, no volatile counts, CONFIRMED tags. OLD predates the standard. |
| **Fidelity** | **NEW (intent); OLD (finest operational)** | med | NEW captures intent far better (ADRs, alternatives-rejected); OLD captured exact signatures the NEW summarized. |
| **Effectiveness** | **NEW to understand/onboard + most agent work; OLD edge to directly operate scripts/contracts/tests at finest detail** | high | The "map vs manual" split is the truest finding of the whole exercise. |

## The dropped 4 docs (judge's reconciled call)
- `content-isolation` → migrated to coding-standards cornerstone; **fine-grained prune (a/b/c) detail + per-profile nest table thinned** (minor loss).
- `repo-presentation` → migrated + its *errors* dropped (net win).
- `release-tracking` → **version-by-version ledger genuinely lost**, and `infrastructure.md:191` still points to it (dangling). Real but minor (git tags hold history).
- `host-tool-capabilities` → **the single biggest loss**: the 25-axis tool×capability matrix is reduced to scattered mentions, not reconstructable. (Low frequency-of-use, but high value when needed.)

## Concrete remediation (prioritized — do NOT revert)
1. **[trivial]** Fix `infrastructure.md:191` dangling `release-tracking.md` ref → repoint to GitHub Releases / drop.
2. **[the real one]** Re-inject the finest operational reference detail the re-derivation thinned: script exit-codes + locking semantics (pipeline-contracts), the **host-tool capability matrix** (biggest single loss), the per-suite coverage map (test-landscape), the field-level STATE schemas (schemas/artifact-schemas). Keep the new structure; deepen its reference layer.
3. **[cleanliness]** De-duplicate the 13-skill phase table across `process-architecture.md` + `workflow-map.md` (one owns; the other links).
4. **[decision]** Record where release history now lives (lean ledger re-instated, or pointer to the real home).

## Meta-finding (most valuable output of this comparison)
This exposes a **systematic bias in the new domain-driven `/aid-discover` engine**, not just these
artifacts: it optimizes for newcomer-clarity + single-concern + intent + conformity, and in doing
so **under-extracts finest-grained operational reference detail** (exact exit codes/locking,
exhaustive enumerations, capability matrices). The act-back operational-sufficiency keystone
*passed* but didn't catch this — its representative task was schema-add (covered), not
"invoke/modify this script at signature level." **Feedback to aid-discover:** the
document-expectations + the act-back mandate should require capturing executable contracts at
**signature level** (args, modes, exit codes, locking) and load-bearing exhaustive enumerations —
or explicitly delegate that depth to code-as-source-of-truth with precise pointers. Worth a
feature-016 / aid-discover refinement.

## Bottom line
NEW wins outright on **4 of 5 C's** (correctness, clarity, cleanliness, conformity) + intent-
completeness + the kb.html (decisive). It trades away **raw reference depth** (completeness's
detail axis) — directionally as the adversary found, but smaller than claimed (load-bearing
contracts survived in summarized form; the finest detail + the host-tool matrix did not). Net: a
genuine step up, with a clear, bounded, recoverable debt.
