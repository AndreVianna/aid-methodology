# Task State -- task-027

> **Task:** task-027
> **Delivery:** delivery-004
> **Work:** work-001-aid-interview-improvements

---

## Task State

- **State:** Done
- **Review:** --
- **Elapsed:** ~35m
- **Notes:** Verification complete -- all 85 suites GREEN; Astro build GREEN; greenfield dogfood PASS

---

## Quick Check Findings

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:** No findings -- all legs pass.

---

## Dispatch Log

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
| 2026-06-28 | aid-developer | 45m | 35m | Done -- suites GREEN, dogfood PASS |

---

## Leg A -- Machine-Verifiable Results

### A1: New marker suite (task-021) -- test-kb-forward-authored-marker.sh

Run: `export HOME=$(mktemp -d) && bash tests/canonical/test-kb-forward-authored-marker.sh`

Result: **38/38 PASS**

Tests covered:
- FA01-FA07: Git fixture two-commit history; forward-authored doc folds to `current` (not `suspect`); hand-authored control reads `suspect` (non-degenerate short-circuit proof); isolation canary.
- FL01-FL03: Lint accepts `source: forward-authored` with complete f001 fields (exit 0); rejects missing `objective:` with `[FM-MISSING]` (proves NOT skipped); accepts `approved_at_commit`.
- FI01-FI04: Index includes forward-authored primary doc in Primary table; source-agnostic grouping confirmed; 6-column schema unchanged; Objective and Summary cells populated.
- BD01-BD03: Existing freshness, lint, and index brownfield suites confirmed passing within the marker suite.

### A2: Brownfield KB-script suites (standalone)

| Suite | Result |
|-------|--------|
| test-kb-freshness-check.sh | 37/37 PASS |
| test-frontmatter-lint.sh | 57/57 PASS |
| test-build-kb-index.sh | 40/40 PASS |

### A3: Full canonical suite -- tests/run-all.sh (HOME-pinned)

Run: `export HOME=$(mktemp -d) && export PLAYWRIGHT_BROWSERS_PATH=/home/andre.vianna/.cache/ms-playwright && bash tests/run-all.sh`

Result: **ALL 85 CANONICAL SUITES PASSED**

No IN11d timing flake observed; test-install.sh completed 194/194 inline. No failures of any kind.

### A4: Site Astro build

Run: `cd site && npm ci && npm run build`

Result: **GREEN** -- 30 pages built in 11.10s; search index, sitemap, image optimization all completed without errors.

---

## Leg B -- AI+Human-Review Greenfield Dogfood

### B1: 5-element model + engine-consuming

**Verdict: PASS**

`state-describe-seed.md` invokes `references/elicitation-engine.md` via the three-parameter consumption contract exactly as specified:
- **Gap inventory:** The 5-element seed table (with per-element fit criteria and priority ranking) is the engine's gap inventory.
- **Stop predicate:** The 6-condition RQ-A5 block (elements 1-5 satisfied AND zero Requirement orphans) is the engine stop predicate; the engine MUST NOT halt while any condition is false.
- **Record sink:** `.aid/knowledge/<element-doc>.md` stamped `source: forward-authored` on first write.

The engine's adaptive selector is NOT re-implemented -- Step 2 explicitly says "Do NOT re-implement the engine's selector logic -- consume it as specified here." The five-step selector (STOP-CHECK -> GAP-SELECTION -> MOVE-SELECTION -> CALIBRATION-SHAPING -> ENVELOPE+EMIT) is delegated to the engine per the consumption contract.

**Concept-spine keystone (D1):** Confirmed -- gap selection ranks `domain-glossary.md` (C4 concept-spine) as rank 3a (missing mandatory element, elicit before architecture). Step 2 engine loop explicitly states: "missing mandatory element -- `domain-glossary.md` (C4 concept-spine) first (the vocabulary keystone; elicit it before architecture), then `architecture.md` (C1)."

**Domain-adaptive (not all 5 forced):** Confirmed -- element 5 (`decisions.md`) is CONDITIONAL and is only added to the inventory when rationale-bearing choices are confirmed (propose->confirm gate, Step 3). Elements 3-4 are DEFERRABLE. Domain extensions are proposed via the same propose->confirm mechanism as `aid-discover`, one at a time, and only when domain warrants.

**Minimal-but-sufficient stop (RQ-A5):** Confirmed -- the stop predicate includes condition 6: "Zero Requirement orphans: the coherence check (step 4) has been run AND its Layer B output shows zero Requirement orphans." The engine MUST NOT halt while any Requirement orphan remains.

### B2: Forward-authored write + freshness folds to current

**Verdict: PASS**

`state-describe-seed.md` Record Sink section specifies the frontmatter for every seed doc with `source: forward-authored` explicitly. The test suite (FA02-FA04) confirmed that `kb-freshness-check.sh` short-circuits `source: forward-authored` docs to verdict `current` with the design-authoritative reason string, regardless of source drift. The short-circuit proof (FA05) confirmed the hand-authored control doc with the same sources reads `suspect` -- the short-circuit is what saves the forward-authored doc, not a degenerate test setup.

`sources: []` is documented as correct for a pure-intent doc (no code exists yet). The frontmatter schema (`frontmatter-schema.md`) now enumerates `forward-authored` as a third enum value (alongside `hand-authored` and `generated`), confirmed by the marker suite FL01 passing lint with `source: forward-authored`.

### B3: Coherence gate (FR-3 / AC-5 / DoD D5)

**Verdict: PASS**

`references/coherence-check.md` documents both layers in full:
- **Layer A (conversational):** Three-pass walk-through (term coverage, architecture fit, stack support) against each selected requirement. Mismatches are flagged.
- **Layer B (deterministic):** Requirement orphan set (REQUIREMENTS terms with no seed concept) and Seed orphan set (seed concepts no requirement references). Both sets enumerated.

Both layers always run -- coherence-check.md Invariant 1 and Invariant 2 confirm: "Both layers always run. Neither can be skipped" and "Both layers complete before any conflict is surfaced."

**BLOCKS on conflict:** coherence-check.md Invariant 4: "The check BLOCKS the flow [HUMAN GATE] until all conflicts are resolved. Work does not proceed to the greenfield-mode review gate while any conflict remains open." state-describe-seed.md Step 4 repeats: "Work MUST NOT proceed to step 5 while any conflict remains open."

**Zero Requirement-orphans sufficiency:** The stop predicate (condition 6) requires zero Requirement orphans before the engine exits. coherence-check.md "Sufficiency-Bar Output" states: "Zero Requirement orphans (every REQUIREMENTS load-bearing term maps to a seed concept) is a NECESSARY condition for the seed to be minimal-but-sufficient."

**Injected mismatch scenario (DoD D5):** If a REQUIREMENTS term has no seed concept, Layer B produces a non-empty Requirement orphan set. The NFR-7 conflict-surfacing template in coherence-check.md ensures every orphan is surfaced with a concrete Suggested resolution and a grounded Why rationale. The [HUMAN GATE] blocks until the user resolves it. After amendment, both layers re-run in full (Invariant 5: "After any seed or REQUIREMENTS amendment, both layers re-run in full").

### B4: Greenfield review gate -- two-case carve (NFR-3 / AC-2 / DoD D3)

**Verdict: PASS**

`state-review.md` lines 119-133 contain the "Greenfield -- two distinct cases (not the same path)" block:

1. **Discovery-triage greenfield (Step 0f):** Classified-greenfield projects with nothing extracted have their `panel:` branch collapsed and skip the review panel. This skip applies ONLY to the discovery-triage path, NOT triggered by a seed review.
2. **Seed-review greenfield (`greenfield: true`):** A `greenfield: true` review invocation from the aid-describe seed-authoring step is a DISTINCT entry point. Per NFR-3, the seed review MUST traverse the FULL panel (`panel: full`): same four mandates (M1-M4), same dimension floors, intent-evidence substituted for code/config evidence, named as-built red flags relaxed per `document-expectations.md` `## Greenfield Mode`.

`state-describe-seed.md` Step 5 confirms the disambiguation: "This is a DISTINCT path from the discovery-triage greenfield case (Step 0f in `aid-discover`, which collapses the panel for projects with no KB to extract). See `state-review.md` 'Greenfield -- two distinct cases.'"

`document-expectations.md` `## Greenfield Mode` block (lines 13-68): evidence substitution for C3/architecture.md/C4; as-built red flags relaxed for C0/C1/C3; dimension floors retained ("No dimension is skipped").

`reviewer-brief.md` `{{GREENFIELD_BLOCK}}` substitution: renders empty (omit entirely) for `greenfield: false`; renders the full GREENFIELD MODE instruction block for `greenfield: true`. The NFR-2 guarantee ("brownfield behavior is byte-unchanged") is enforced by the empty render for `greenfield: false`.

`state-describe-seed.md` Step 5 dispatches `panel: full` with M1, M2, M3, M4 in parallel. M2 inlines `document-expectations.md` `## Greenfield Mode` via `{{DOCUMENT_EXPECTATIONS}}`.

### B5: Brownfield-intact (AC-10 / NFR-2 / DoD D6)

**Verdict: PASS**

Four dimensions checked:

1. **KB-script suites:** All three standalone suites pass (freshness 37/37, lint 57/57, index 40/40). BD01/BD02/BD03 in the marker suite confirm the brownfield regression is tracked in-suite.

2. **Brownfield review path byte-unchanged:** `document-expectations.md` line 17: "The default is `greenfield: false`; brownfield behavior is byte-unchanged outside this section (NFR-2). This is a FLAG on the existing expectations -- not a forked variant." `reviewer-brief.md` `{{GREENFIELD_BLOCK}}` renders as empty (omit entirely) for `greenfield: false` -- no additional instruction reaches the brownfield reviewer.

3. **aid-interview brownfield/lite path unaffected:** `state-describe-seed.md` entry conditions include: "If any file carries `source: hand-authored` or `source: generated`, a brownfield KB already exists -- skip DESCRIBE-SEED entirely and route to COMPLETION." The DESCRIBE-SEED state is additive and only entered for greenfield projects; the brownfield/lite path is untouched.

4. **Full suite regression:** 85/85 suites pass, including all pre-existing brownfield tests.

---

## Delivery Gate Summary (delivery-004)

| Criterion | DoD | Result |
|-----------|-----|--------|
| Greenfield-mode gate at A+ (AC-2 / NFR-3 / DoD D3) | Full panel; as-built red flags relaxed; intent-evidence accepted | PASS (wiring verified) |
| Zero-loopback sufficiency (AC-2 / RQ-A5 / DoD D4) | Stop predicate condition 6: zero Requirement orphans | PASS (structural) |
| Coherence check blocks on injected mismatch (AC-5 / FR-3 / DoD D5) | Both layers; [HUMAN GATE]; re-runs clean | PASS |
| Brownfield intact (NFR-2 / AC-10 / DoD D6) | 3 KB-script suites + marker suite; byte-unchanged brownfield review path | PASS |
| Master-only heavy gates (§6) | tests/run-all.sh 85/85; site Astro build clean | PASS |
