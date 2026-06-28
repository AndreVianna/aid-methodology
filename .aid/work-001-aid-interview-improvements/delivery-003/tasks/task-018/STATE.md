# Task State -- task-018

> **Task:** task-018
> **Delivery:** delivery-003
> **Work:** work-001-aid-interview-improvements

---

## Task State

- **State:** Done
- **Review:** --
- **Elapsed:** ~1h
- **Notes:** Dispatched (aid-developer) — delivery-003 verification: brownfield tests + dogfood-transcript review. All machine gates GREEN (83 suites). All dogfood ACs PASS. Two [LOW] documentation observations recorded below (no behavioral impact, no blocker).

---

## Verification Results

### Leg A -- Machine-verifiable brownfield-intact (AC-10 / NFR-2)

| Suite | Result | Count |
|-------|--------|-------|
| `tests/canonical/test-parse-recipe.sh` (19 units) | PASS | 113 tests passed, 0 failed |
| `tests/canonical/test-recon-classify.sh` | PASS | 37 tests passed, 0 failed |
| `tests/canonical/test-path-fixtures.sh` | PASS | 20 tests passed, 0 failed |
| `tests/canonical/test-pipeline-status-walkthrough.sh` | PASS | 166 tests passed, 0 failed |
| `tests/run-all.sh` (HOME-pinned, PLAYWRIGHT_BROWSERS_PATH set) | PASS | ALL 83 CANONICAL SUITES PASSED |
| `site` Astro build (`npm ci && npm run build`) | PASS | 30 pages built in 11.20s |

**Brownfield diff verification:**
- `canonical/aid/scripts/interview/parse-recipe.sh` -- diff vs master: 0 lines (untouched)
- `canonical/aid/scripts/kb/recon-classify.sh` -- diff vs master: 0 lines (untouched)
- `canonical/aid/recipes/` -- diff vs master: 0 lines (untouched)
- `canonical/skills/aid-discover/` -- diff vs master: 0 lines (untouched)
- `state-triage.md` "Unit-testable mapping rules" section -- byte-identical to master (confirmed by diff); routing/override/recipe-offer tables hold (D3 confirmed)

---

### Leg B -- AI+human-review dogfood

#### AC-3: No bare-question scan -- PASS

**Structural enforcement (Enforcement 1):**
- `elicitation-engine.md` Step 5 delegates ALL emissions to `advisor-stance.md` NFR-7 envelope. No secondary emission path exists in the engine. Confirmed.
- `advisor-stance.md` "Enforcement 1: Structural": "The engine driver emits questions ONLY through this envelope. There is no secondary emission path." Confirmed.

**Pre-emit gate (Enforcement 2):**
- Self-check in `advisor-stance.md` verifies `Suggested:` present + concrete and `Why:` present + grounded before every emission. Straw-man-first (Move 1) guarantees a suggestion always exists even for open questions. Confirmed.

**D1 opener NFR-7 compliance by construction:**
- `state-triage.md` Step 1: D1 opener text carries full `Suggested:` + `Why:` fields hardwired. Confirmed.
- `state-continue.md` fallback: identical D1 opener text with `Suggested:` + `Why:`. Confirmed.
- `elicitation-engine.md` "D1 Fixed Opener": shows full envelope; explains why self-check is not needed (both fields hardwired). Confirmed.

**Move playbook patterns:**
- Every move (2-9) in `move-playbook.md` shows `Suggested:` + `Why:` in its conversational pattern. Confirmed.

**Calibration ASK NFR-7 compliance:**
- `calibration.md` Part B NFR-7 example shows full `Suggested:` + `Why:` envelope. Confirmed.

**[LOW] Observation (Step 3 route-confirmation format):**
- `state-triage.md` Step 3 route-confirmation turn uses the `[1]/[2]/[3]` option format without explicit `Suggested:`/`Why:` label text. The SPEC explicitly identifies this as "the NFR-7 straw-man reflect-back" -- the "Looks like X" phrasing IS the straw-man (suggestion) and the inferred evidence IS the rationale. Not a bare question per the SPEC; acceptable. No behavioral impact.

---

#### AC-4: Calibration + advisor behaviors -- PASS

**Opener is NEVER the calibration question:**
- `calibration.md` § "AC-4 and D1": "Turn 1 is ALWAYS the D1 fixed opener (the what+why question). It is not the calibration question. The calibration ASK is NEVER turn 1." Confirmed.
- `elicitation-engine.md` Invariant 6: same guarantee. Confirmed.

**Calibration ASK -- gated, early follow-up (not turn 1), NFR-7-compliant:**
- `calibration.md` Part B gating rule: fires only when calibration state is `Unknown` AND at least one substantive answer received (NOT turn 1). Confirmed.
- `elicitation-engine.md` Step 2 Gap rank 2: consistent gating. Confirmed.
- `calibration.md` Part B "NFR-7 envelope on the calibration ASK": "Like every question the engine emits, the calibration ASK MUST carry the full NFR-7 envelope." Example shown. Confirmed.

**Depth divergence (Expert vs Novice):**
- `calibration.md` Depth-Shaping Table: Expert=Lighter (fewer why-steps, confirm-and-move, skip scaffolds); Novice=Heavier (more drawing-out, teaching scaffolds, more example-probes, more why-steps). Confirmed.
- "An Expert session and a Novice session on the same prompt must read as different conversations." Confirmed.

**Five AC-4 user-move handlers, all deferring to user:**
| User move | Handler present | Decision deferred? |
|-----------|----------------|-------------------|
| "I don't know" | Guide + scaffold, straw-man offered, assumption marked if accepted | Yes |
| "What do you recommend?" | Recommend as real expert with full rationale; surface as Suggested | Yes |
| "Explain the pros and cons" | Explain trade-offs at calibrated depth; re-offer question | Yes |
| "Explain it like I'm a junior" | Teach at novice depth (temporary shift); re-ask after | Yes |
| User asserts something mistaken | Cordially disagree with reasons; return call explicitly | Yes |
All five confirmed in `advisor-stance.md` "The Five User-Move Handlers".

---

#### Engine-not-form (D1/D2/NFR-4) -- PASS

- `elicitation-engine.md` "Engine Overview": "The D1 fixed opener. One fixed turn. Every session starts here. It is the ONLY scripted turn in the entire interview. After the user answers it, control passes to the adaptive loop permanently." Confirmed.
- Invariant 4: "The D1 opener is the ONLY fixed turn; every adaptive loop turn is engine-chosen from the gap inventory; no hidden question list exists." Confirmed.
- `move-playbook.md` "Sequence Rule: Default, Not a Script": "The engine does NOT march through moves in order. It picks the move for the highest-priority open gap, whatever that gap is. The sequence emerges from the gap inventory." Confirmed.
- `elicitation-engine.md` Step 1: "The engine halts when the work is minimal-but-sufficient for its host purpose -- NOT at the end of a list. This is the discipline grill-me lacks: the engine stops, it does not 'ask every branch.'" Confirmed.
- Invariant 5: "The loop halts at minimal-but-sufficient (consumer's stop predicate fires), not at the end of a list." Confirmed.

---

#### Triage (AC-7 / FR-5) + opener de-dup -- PASS

**D1 opener fires once in TRIAGE:**
- `state-triage.md` Step 1 emits D1 opener once. Confirmed.

**Opener carried forward via `**Opener:**` field (Step 6 de-dup):**
- `state-triage.md` Step 6: All five STATE.md output variants (full, escalated, lite-no-recipe, lite-no-override, lite-override) include `- **Opener:** {opener-intent}`. Confirmed.

**CONTINUE skips opener when `**Opener:**` field present:**
- `state-continue.md` "Entry: opener skip check": "If the `**Opener:**` field is present in `## Triage` ... -> the D1 opener already fired in TRIAGE. ... Do NOT re-emit the D1 opener." Confirmed.

**Fallback emits opener when field absent:**
- `state-continue.md` "If NEITHER signal is present (legacy direct-CONTINUE entry, pre-TRIAGE in-flight work, or loopback with no triage record): If all REQUIREMENTS.md sections are Pending, emit the D1 fixed opener." Confirmed.

**Gap-targeted questions in both KB contexts:**
- `state-triage.md` KB-context detection: Full brownfield / Seed / No KB all handled at state entry. Confirmed.
- `state-triage.md` Step 1b KB-context gap-targeting: "Full brownfield KB: if a signal is already answered in the KB, convert the gap to a confirm-not-elicit straw-man ... Seed KB: anchor straw-mans on the declared concept-spine ... No KB: draw all signals out from scratch." Confirmed.
- NFR-7 holds in all KB contexts. Confirmed.

**Correct routes (single-slice -> lite, sprawling-backbone -> full):**
- `state-triage.md` Unit-testable routing table: "fix the login crash on special characters" -> lite; "rewrite the whole billing subsystem across 4 services" -> full. Confirmed.

**[LOW] Documentation imprecision (elicitation-engine.md opener de-dup):**
- `elicitation-engine.md` "Opener de-dup" section refers to "a `## Triage Opener:` field in STATE.md" -- imprecise; the actual field is `- **Opener:** {opener-intent}` under the `## Triage` heading (a list item, not a sub-heading). The consuming doc (`state-continue.md`) checks for "`**Opener:**` field in the `## Triage` block" which is correct. No behavioral impact; documentation-only imprecision.

---

## Quick Check Findings

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:**
  - [LOW] `elicitation-engine.md` "Opener de-dup" uses "## Triage Opener:" (section-style) vs actual field `**Opener:**` under `## Triage`. Consuming doc correct; no behavioral impact. Deferred.
  - [LOW] `state-triage.md` Step 3 route-confirmation turn uses `[1]/[2]/[3]` option format without explicit `Suggested:`/`Why:` labels. SPEC classifies it as "NFR-7 straw-man reflect-back" (not a bare question). No behavioral impact. Accepted.

---

## Dispatch Log

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
| 2026-06-27 | aid-developer | 1h | ~1h | DONE -- all gates GREEN |
