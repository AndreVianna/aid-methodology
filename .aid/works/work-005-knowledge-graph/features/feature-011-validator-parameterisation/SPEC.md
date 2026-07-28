# Validator Parameterisation And Toolchain Reuse

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.5 (FR-12), §5.6 (FR-17), §7 (C-2–C-5), §9 (AC-17) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Finding 4 [HIGH] fixed — the NM.1 waiver removed (its premise was false: NM.1 requires the literal token `mermaid`, so a non-Mermaid bundle passes unmodified). All three NM sub-checks now enforced for both artifacts. The whole carve-out re-derived from the check bodies and reduced to two **contingent** carve-outs: S2 (only under CDN packaging) and `validate-visuals.mjs` T2 (only for an SVG live surface) | /aid-specify |
| 2026-07-28 | Reference fix following the owner's feature-006 corrections: the `package.json` ESM-marker row is **removed** from the new-canonical-files inventory and from the Feature Flow, the shared predicate is listed at `canonical/aid/scripts/graph/coverage-predicate.mjs`, `GR05` is repointed to assert both `.mjs` files render and import with no marker, and the `_TEXT_EXTENSIONS` consequence for `.mjs` is stated. No decision in this SPEC changes | /aid-specify |
| 2026-07-28 | **Split three ways (owner decision).** This feature narrows to **validator parameterisation and toolchain reuse** and keeps the 011 number so features 007/008/009/010's cross-references do not churn. Canonical registration + count reconciliation moved to **feature-012**; documentation surfaces + ship-time verification moved to **feature-013**. D1, D2, D6, L1, L4, the render Feature Flow and External Integrations left this SPEC; D3, D4, D5 and D7 keep their identifiers deliberately (see the scope note) | /aid-specify |
| 2026-07-28 | Three pre-existing defects this SPEC routed elsewhere are now **fixed on this branch** and restated as such: the summarize Node floor is ≥ 20 (D7), `grade-summary.sh` scores `NM` at 70 pts max (D3), and `gen-reference.test.mjs` is re-anchored to derived set comparisons (feature-012 D2). `U1` and `U2` are removed from the open-findings list | /aid-specify |
| 2026-07-28 | Folder renamed to `feature-011-validator-parameterisation` and H1 retitled to match the narrowed scope (owner action — both sit above the separator / are path changes the split could not make) | /aid-specify |
| 2026-07-28 | Final-gate finding fixed — scope note no longer claims the requirements half still carries the old title; it records the retitle and rename instead | /aid-specify |

## Source

- REQUIREMENTS.md §5.5 (FR-12 — reuse the existing HTML toolchain at the script layer: single-file
  assembly, contrast checking, HTML output validation, browser-backed visual validation)
- REQUIREMENTS.md §5.6 (FR-17 — the runtime-script rule remains in force for the Knowledge Base
  summary and the graph is a documented exception, which means the **shared** validator must be
  parameterized rather than forked)
- REQUIREMENTS.md §5.9 Decision paragraph ("Accepted cost: one more skill in the canonical-to-
  profiles render and the install manifests, plus some duplicated preflight/writeback prose")
- REQUIREMENTS.md §7 Constraints — **C-2** (authored canonically, rendered to every host profile;
  never hand-maintained per profile), **C-3** (the install and emission manifests are lockstep
  hazards and must stay consistent), **C-4** (reuse rather than reimplement; do not fork),
  **C-5** (runtime version floor; browser-backed visual validation must degrade gracefully when
  the browser is not provisioned)
- REQUIREMENTS.md §8 (D-3 — depends on the existing script layer remaining stable, or on
  extracting the shared pieces to a neutral location)
- REQUIREMENTS.md §9 (AC-17)

**Carries a known debt hazard.** The Knowledge Base flags the install-manifest lockstep problem as
**HIGH-severity debt**: several manifests independently declare the shipped file set, and a single
missed update silently ships a broken install for one channel. Adding a skill and a script area
touches exactly that surface. This feature owns keeping them consistent, and it should be reviewed
with that debt item in hand. The Knowledge Base also records that after any canonical edit the
**full** profile generator must run, not a per-script renderer, or the render-drift gate fails on
stale emission manifests.

**Currently absorbs tests and documentation.** This feature also carries the test suites for the
new skill and the documentation surfacing — the reference documentation, the site's skill catalogue,
the project readme, and the Knowledge Base capability entry at ship time. That makes it the widest
feature in the set and the most likely split candidate on review; the natural cut is a separate
tests-and-documentation feature, or per-feature test ownership with documentation left here.

**Dependency position.** The earliest non-research feature — the reuse decision and the wiring must
land before other features have a place to put code. Extended late, during the view work, for the
FR-17 validator parameterization.

## Description

The existing Knowledge Base summary skill already owns a working HTML toolchain: it assembles a
single self-contained file, checks colour contrast, validates the HTML output, and drives a browser
to confirm the result actually renders. None of that should be built a second time. This feature
wires the new skill into those scripts rather than copying them, which is why the two skills were
kept separate but the machinery was not duplicated — the machinery already lives outside either
skill, in a shared script area.

Reuse has one sharp edge. The existing validator asserts that no runtime drawing engine ships in
the output — a guardrail that must keep protecting the Knowledge Base summary, while the graph, which
is interactive by design, is a documented exception to it. So the shared validator has to be
parameterized to express both rules at once. Forking it into two near-copies would satisfy neither
the reuse constraint nor the maintenance argument, and would guarantee the copies drift.

Beyond reuse, a new skill has to actually ship. It is authored once in the canonical source and
rendered out to every host profile by the existing renderer; it is never hand-maintained per
profile, and the rendered copies are never edited. Adding it touches the manifests that declare what
gets installed and what gets emitted, and those manifests have to stay in step with each other —
this is a known hazard in this project, not a theoretical one. The new skill also needs to appear
where users and contributors look for skills: the reference documentation, the site's skill
catalogue, and the project readme.

Finally, the browser-backed validation has to behave sensibly when no browser is provisioned,
degrading with a clear message rather than failing the run — matching how the existing summary skill
already handles it.

## User Stories

- As the **AID methodology owner**, I want the new skill to reuse the existing HTML machinery rather
  than fork it, so that one fix improves both artifacts instead of one of two divergent copies.
- As the **AID methodology owner**, I want the runtime-script guardrail to keep protecting the
  Knowledge Base summary while the graph is an explicit exception, so that the carve-out is
  deliberate and cannot silently widen.
- As a **maintainer/architect**, I want the skill authored once canonically and rendered to every
  host profile, so that no profile drifts and no rendered copy needs hand-maintenance.
- As a **maintainer/architect**, I want the install and emission manifests updated together, so
  that no distribution channel silently ships a broken install.
- As a **newcomer to the project**, I want the new skill listed where the other skills are
  documented, so that I can discover it without reading the source tree.

## Priority

Must

## Acceptance Criteria

- [ ] AC-17: Given the new skill's HTML pipeline, when its implementation is reviewed, then it
      invokes the existing summary skill's scripts rather than forked copies, and no duplicated
      assembler or validator logic is present.
- [ ] Given the shared HTML output validator, when it runs against the Knowledge Base summary and
      against the graph view, then the no-runtime-engine assertion still holds for the summary and
      the graph is permitted as a documented exception — expressed by parameterization, not by a
      forked validator.
- [ ] Given the new skill authored in the canonical source, when the full profile render runs, then
      the skill appears in every host profile install tree and no profile copy is hand-maintained.
- [ ] Given the new skill and its script area, when the install and emission manifests are checked,
      then all of them account for the added file set consistently — no manifest is left behind.
- [ ] Given a canonical edit for this work, when the render is verified, then the full generator has
      been run and the render-drift check passes with no stale emission manifest.
- [ ] Given an environment where the validation browser is not provisioned, when validation runs,
      then it degrades gracefully with a clear message rather than failing the run, and the runtime
      version floor is reported when unmet.
- [ ] Given the shipped skill, when the reference documentation, the site's skill catalogue, and the
      project readme are checked, then the new skill is listed in each.
- [ ] Given the new skill, when its test coverage is checked, then automated suites exercise its
      preflight, its staleness behaviour, and its artifact validation, consistent with how the
      existing summary skill is covered.

---

## Technical Specification

> Grounded in `canonical/aid/scripts/summarize/` (`validate-html-output.sh`, `grade-summary.sh`,
> `assemble.sh`, `validate-visuals.mjs`, `contrast-check.mjs`, `package.json`, `package-lock.json`,
> `summarize-preflight.sh`, `playwright-provisioning.md`),
> `canonical/skills/aid-summarize/references/state-preflight.md`,
> `canonical/aid/scripts/{grade.sh,config/read-setting.sh}`,
> `tests/canonical/test-guardrails-d012.sh`, `.github/workflows/test.yml`, and the KB docs
> `technology-stack.md`, `test-landscape.md`, `coding-standards.md`, `tech-debt.md`.

### Scope after the three-way split

This feature was split by owner decision on 2026-07-28. It now owns exactly one mechanism: **the
shared HTML toolchain — reusing it, and parameterising it if and only if the scripts genuinely
require it.** It is the late-landing part of the original feature and the only part that can regress
`kb.html`, which is why it is specified with a proof obligation rather than a checklist.

| Moved to | What went |
|---|---|
| **feature-012 — canonical registration and count reconciliation** | D1 (registration inventory), D2 (count drifts), D6 (third-party adoption gate), L1 (new canonical files), the render Feature Flow, External Integrations, and migration rows M2–M4/M6. Constraints **C-2** and **C-3** land there. |
| **feature-013 — discoverability and ship-time verification** | L4 (documentation surfacing), `test-graph-skill-registration.sh`, the ship-time KB updates, and the aggregate HOME-pinned suite gate. |

**Two notes a reviewer will otherwise trip on.**

1. **The `D` identifiers are deliberately not renumbered.** D3, D4, D5 and D7 keep the numbers they
   had, and D1/D2/D6 are simply absent. feature-010's SPEC cites "feature-011 D3" and "feature-011
   D7" by number in five places, and features 007, 008 and 009 reference this feature for the
   validator carve-out. Renumbering would churn cross-references in specs this split is not supposed
   to disturb, for no gain — a stated gap is cheaper to read than a silent renumber.
2. **The requirements half above the separator is otherwise unchanged.** The H1 has since been
   retitled to "Validator Parameterisation And Toolchain Reuse" and the folder renamed to
   `feature-011-validator-parameterisation` (owner action, recorded in the Change Log), but the half
   still carries the C-2/C-3 source lines and the three acceptance
   criteria now discharged by feature-012 (render coverage, manifest consistency, render-drift) and
   the two discharged by feature-013 (documentation surfacing, test coverage). Those criteria are not
   orphaned — each is restated verbatim in the requirements half of the feature that now owns it.
   **This feature's own criteria are AC-17, the validator-parameterisation criterion, and the
   graceful-degradation criterion**, and nothing below this line addresses the other five.

### Data Model

#### D1, D2, D6 — moved to feature-012

The registration inventory, the count-surface reconciliation, and the third-party adoption gate now
live in **feature-012 § D1, D2 and D3** respectively. Nothing in this feature depends on them except
one cross-reference, stated here so it is scheduled rather than discovered: feature-012's gate
condition **G8** (documented prerequisites under CDN delivery) is discharged in part by this
feature's `S2 [N/A]` validation line, which is contingency **C1** below. Both fire on the same
trigger — FR-18 selecting external delivery — so `/aid-detail` should schedule them together.

#### D3 — The validator carve-out: what the scripts actually require

The requirements half anticipates a carve-out for the shared validators. Reading them line by line
shrinks it to almost nothing, and getting that boundary right matters more than getting it wide: a
waiver granted for a check that would have passed anyway is not neutral, it is a permanently open
door. So the carve-out is derived here from the check bodies, not from what an interactive artifact
"obviously" needs.

**`validate-html-output.sh`, check by check, against `graph.html` as feature-007 specifies it:**

| Check | The actual test | Verdict on the graph |
|---|---|---|
| `NM.1` | awk, one rule: `!is_md_payload && length(buf) > 100000 && tolower(buf) ~ /mermaid/`. It needs *all three* — an executable (non-`text/markdown`) inline `<script>`, over 100 KB, **whose text contains the literal token `mermaid`**. | **Passes unmodified.** A D3, Cytoscape, or hand-written interaction bundle contains no such token, however large it is. The size threshold alone triggers nothing. |
| `NM.2` | `grep -qE 'mermaid\.initialize\('` | **Passes unmodified.** |
| `NM.3` | `grep -qE '<script[^>]+src="https?://[^"]*mermaid[^"]*"'` | **Passes unmodified.** |
| `S2` | `grep -E '<script[^>]+src="https?://'` and `<link[^>]+href="https?://'` | **Passes under the reference local-vendored layout** (feature-007 § Packaging). Fails **only** if FR-18 selects delivery that genuinely fetches from a CDN — which FR-16 now permits but does not require. |
| `H1`, `A1`–`A5`, `L1`, `L2`, and the structural checks (`skip-link`, `<noscript>`, `color-scheme`) | as written | **Pass by construction** — feature-007 reuses `component-css.css`, `lightbox.js`, and the summary shell wholesale, which is exactly the code these checks grep for, and ships the `<noscript>` and skip-link the structural checks require. |

**The NM.1 waiver in the previous revision of this SPEC was wrong, and removing it is a
correctness fix, not a simplification.** It rested on reading NM.1 as a size heuristic. It is a
size-*and*-token heuristic, and the token is the operative half. Worse, granting the waiver would
have been actively harmful: marking NM.1 `[N/A]` under a `graph` profile is precisely what would let
a Mermaid engine bundled inline into `graph.html` slip past decision **D-012**, leaving only NM.3
(CDN `<script src>`) as a guard against it. **All three NM sub-checks stay enforced for both
artifacts, unconditionally.**

**`validate-visuals.mjs`:** its collector takes `.diagram-box`, `.infographic`, and every outermost
`<svg>` not inside one of those. For an SVG live graph surface that means the drawing surface itself
is collected, and then:

| Check | On an SVG live graph surface |
|---|---|
| `T2` — sibling `<g>` bounding boxes may not overlap by more than 20% of the smaller area | **Collides by design.** Overlapping semantic groups are what a force-directed layout *is*. This is the one genuine collision in either script. |
| `T1` — rendered font-size ≥ 10 px | **Not waived.** A node label too small to read is a real legibility defect, and the fix is to render it larger, not to stop measuring it. |
| `T3`, `T4` | **Not waived.** A collapsed surface or one clipped at 732/390 px is a defect on any artifact. |

A `<canvas>` or WebGL surface is not collected at all, so no exclusion is needed for it.

#### The two contingencies, and why neither is unconditional

Both remaining carve-outs depend on decisions this work has not taken. Specifying them as
**contingent** is the honest form, and it lets `/aid-detail` schedule each behind its trigger rather
than producing work that may prove unnecessary.

| # | Contingency | Trigger | Mechanism if triggered |
|---|---|---|---|
| C1 | S2 waiver on `graph.html` | FR-18 selects delivery that fetches from an external origin | `validate-html-output.sh <html> [--kb-dir DIR] [--profile kb-summary\|graph]`, where `graph` differs from `kb-summary` in **exactly one** check: S2 is reported `[N/A]` with its reason. Every other check, including all of NM, is identical between the two profiles. |
| C2 | T2 exclusion on the live surface | feature-002 selects an **SVG** live drawing surface | `validate-visuals.mjs <html> [--check-only] [--min-font-size N] [--profile kb-summary\|graph]`, where `graph` reports T2 as `[N/A]` **for the single element carrying the live-surface marker class** and leaves T1, T3, T4 enforced on it and all four enforced on every other visual. |

If FR-18 selects vendoring and feature-002 selects Canvas or WebGL, **neither contingency fires and
no shared validator is edited at all** — the strongest possible reading of C-4 and AC-17. That
outcome is the one this SPEC expects, since feature-007's reference layout is local-vendored.

Five properties keep either mechanism "parameterised, not weakened" (REQUIREMENTS.md §5.6
consequence 1):

1. **`kb-summary` is the default, so `kb.html`'s behaviour is byte-unchanged.**
   `grade-summary.sh` invokes `bash "$SCRIPT_DIR/validate-html-output.sh" "$HTML"` with no extra
   argument, and the CI visual job invokes `validate-visuals.mjs` with the HTML path alone. Neither
   call site is edited. Their assertion sets, output text, and exit statuses are identical before and
   after — which is what makes the claim *provable* rather than asserted (see D4).
2. **The profile table lives once, in the script header, as a closed set.** An unrecognised
   `--profile` value exits `2` (usage error, per `.aid/knowledge/coding-standards.md` Exit Codes, and
   the code `validate-visuals.mjs` already returns for an unknown flag), so a third policy cannot be
   introduced at a call site — only by editing the table.
3. **Each profile waives exactly one named check.** Not a category, not a script, not a severity
   band. A carve-out that can be stated in one line is a carve-out a reviewer can hold.
4. **The waiver is scoped to an element, not a page, wherever it can be.** C2 suppresses T2 on the
   marked live surface only; an authored legend or infographic on the same page is still fully
   checked. FR-17's exception is for the drawing surface, and the mechanism says so literally.
5. **A waived check prints why it was waived.** `S2. Offline render [N/A] external assets permitted
   for profile 'graph'` rather than silently passing, so the policy in effect is visible in the
   validation log. That is also how AC-6's "runtime prerequisites documented explicitly" obligation
   is discharged at validation time.

**The `NM` scoring gap this SPEC previously reported is now FIXED on this branch, and the fix
strengthens the argument above.** The earlier revision recorded that `grade-summary.sh`'s pool was
`COV D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2` with **no `NM` key**, so an `NM`-only failure fell into
the per-check recovery branch, found every individual pass marker, and awarded full points — meaning
an `NM` failure could not reduce `kb.html`'s Machine Grade. Re-verified on disk after the fix:

| What changed | Verified |
|---|---|
| `NM` is a scored key | The pool loop now reads `for k in COV D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2 NM`, in all three places it appears (results init, `AUTO_MAX` summation, report) |
| It carries weight | `WEIGHTS[NM]=2`, the same as `S2`, with `CHECK_NAMES[NM]="No-Mermaid-engine (D-012)"` |
| The maximum moved | **68 → 70 points**; the header now reads "70 pts max" and "A+ requires … >= 98% of 70 pts" |
| The result is derived independently of `S2` | `grep -qE "NM\..*\[PASS\]" "$HTML_LOG"` — pattern-matched against the validator's own `NM. No-Mermaid-engine [PASS]` line, precisely so an `NM`-only failure cannot be masked by a passing `S2`. Its inline comment says so. |

The consequence for this feature is that D-012's guardrail is now scored on **both** artifacts by
symmetrical mechanisms: `grade-summary.sh` scores `NM` for `kb.html`, and feature-010's
`grade-graph.sh` gives `V-NM` and `V-S2` explicit `[HIGH]` rubric rows for `graph.html` (its D4).
Whichever way a Mermaid engine tried to enter, a grade moves. That is the state the earlier revision
argued for and could only report; it no longer needs reporting.

#### D4 — Proving `kb.html` is unchanged

If neither contingency fires, this is trivial: no shared validator is edited, so there is nothing to
prove. The obligations below apply **if and when C1 or C2 is triggered**, and they are specified now
so the trigger does not arrive without its guard.

| # | Proof | What it rules out |
|---|---|---|
| 1 | The existing call sites are untouched — `grade-summary.sh`'s `bash "$SCRIPT_DIR/validate-html-output.sh" "$HTML"` and the CI job's `validate-visuals.mjs <html>` — and the new argument's absence selects `kb-summary` | A call-site change smuggling the graph policy into the summary path |
| 2 | `tests/canonical/test-guardrails-d012.sh` continues to pass unmodified | Regression of the `S2`/`NM` guardrails. This suite already builds its **own** compliant `kb.html` fixture inline and asserts `NM.1`/`NM.2`/`NM.3` and `S2` against it, plus that `validate-html-output.sh` still contains the `S2` and `NM` sections. It is the existing pin, and it satisfies A-6 by construction. |
| 3 | A new golden-output assertion in `tests/canonical/test-validate-html-profiles.sh`: run the edited validator over the same fixture with no `--profile` before and after the change and diff the **full stdout** | Any change to the summary path's *reported text or tally*, not just its verdict |
| 4 | The same suite runs the fixture with `--profile graph` and asserts the diff against the default run is **exactly one line** — the S2 line for C1, the T2 line for C2 | The carve-out widening beyond its single named check, which is the failure mode D3 property 3 exists to prevent and the one no golden-output test of the default path can catch |

Proofs 3 and 4 are the load-bearing pair: 1 and 2 would both survive a refactor that accidentally
reordered or renumbered the summary's checks, and 1–3 would all survive a `graph` profile that
quietly waived a second check.

#### D5 — Reuse map (C-4 / AC-17)

| Existing script | Reused for the graph how | Change needed |
|---|---|---|
| `canonical/aid/scripts/summarize/assemble.sh` | Invoked with `--src .aid/.temp/graph/graph-src --output .aid/knowledge/graph.html --manifest <file>`. Already fully parameterised on all three; its deterministic manifest-ordered concatenation is exactly what the graph needs for FR-32-style reproducibility of the shell. Its **defaults are untouched** (`SRC_DIR=".aid/.temp/summarize/summary-src"`, `OUTPUT=".aid/knowledge/kb.html"`), so `test-guardrails-d012.sh`'s `C1b` and `NM-e` assertions on this file continue to hold. | **None** |
| `validate-html-output.sh` | `bash validate-html-output.sh .aid/knowledge/graph.html --kb-dir .aid/knowledge` — every check passes as written, including all three `NM` sub-checks | **None**, unless contingency **C1** fires (D3), in which case add `--profile` |
| `contrast-check.mjs` | `node contrast-check.mjs .aid/knowledge/graph.html` — takes the HTML path as its argument | **None** |
| `validate-visuals.mjs` | `node validate-visuals.mjs .aid/knowledge/graph.html` — takes the HTML path; its `try { await import('playwright') } catch` block already SKIPs to exit 0 with an actionable message | **None**, unless contingency **C2** fires (D3), in which case add `--profile` |
| `canonical/aid/scripts/summarize/package.json` + `package-lock.json` | The Playwright provisioning the graph's visual validation depends on, already emitted into every profile tree (present as records in each `emission-manifest.jsonl`) | **None** unless a build step is adopted, which is feature-012's D3 gate |
| `canonical/aid/scripts/grade.sh` | Grades `.aid/.temp/review-pending/graph.md` | **None** |
| `canonical/aid/scripts/config/read-setting.sh` | Resolves the minimum grade for skill `graph` through the standard per-skill → top-level → default chain | **None** |
| `canonical/aid/scripts/summarize/grade-summary.sh` | **Not reused.** feature-010's `grade-graph.sh` is a sibling orchestrator. | — |

`grade-summary.sh` is the one deliberate non-reuse, and the reason is substantive rather than
convenient: it hardcodes `KB_DIR=".aid/knowledge"` and
`MANUAL_CHECKLIST_FILE=".aid/.temp/summarize/manual-checklist.json"`, and its **70**-point pool
(68 before the `NM` fix — D3) is centred on `COV`, resolved-doc-set coverage of `kb.html`. Importing `COV` into the graph's gate would
grade the Knowledge Base's completeness, which FR-28 explicitly forbids. Reuse therefore happens one
layer down, at the leaf validators, where every actual check lives. AC-17's test is "no duplicated
assembler or validator logic", and it is satisfiable by inspection: diff `grade-graph.sh` against
`grade-summary.sh` and no check body is shared, because `grade-graph.sh` contains none — it invokes
the same leaves.

#### D7 — Node and Playwright degradation (C-5)

**The Node-floor inconsistency this SPEC previously reported is now FIXED on this branch.** The
earlier revision recorded that `/aid-summarize` could pass its own preflight on Node 18 and then run
validators whose `package.json` declares Node 18 unsupported, and routed the fix elsewhere because
raising another skill's floor was outside a graph feature's scope. The owner had it fixed directly.
Re-verified on disk:

| Source | Now declares | Verified |
|---|---|---|
| `canonical/aid/scripts/summarize/summarize-preflight.sh` — Check 5 | Node ≥ **20** | `[ "$NODE_VERSION_MAJOR" -lt 20 ]` guards, the message reads `Node.js >= 20 is required (you have …)`, and the comment block cites `"engines": { "node": ">=20" }` alongside Playwright 1.61.1 as the reason |
| `canonical/skills/aid-summarize/references/state-preflight.md` — item 5 | Node ≥ **20** | "Node.js >= 20 is available … the summarize validators declare `"engines": { "node": ">=20" }` … Node 18/19 is insufficient" |
| `canonical/aid/scripts/summarize/package.json` | `"engines": { "node": ">=20" }` | Unchanged — it was always the correct floor; the preflight now matches it |
| `.aid/knowledge/technology-stack.md` | **Four** Node floors, with the validators broken out | The languages row reads ">=18 (npm wrapper); >=20 (summarize validators); CI pins 20"; the Version Concerns gotcha reads "**Four** different Node floors across contexts"; a per-context note and a changelog entry record the change |
| REQUIREMENTS.md C-5 | "Existing validator tooling requires Node.js ≥ 20" | Now satisfied by the tooling rather than contradicted by it |

Two consequences, both simplifications:

- **The split resolution is gone.** There is no longer a `/aid-graph`-adopts-20-while-summarize-stays-18
  asymmetry to explain. feature-010's `graph-preflight.sh` P5 asserts ≥ 20 and so does its sibling;
  P5's floor is now the *same* floor, not a deliberately higher one, and feature-010's SPEC says so.
- **C-5's version-floor half is discharged by existing code.** This feature introduces no new floor
  and edits no preflight. What remains of C-5 here is the degradation half below.

**Playwright degradation** reuses the existing shape exactly, because it is already correct:

| Condition | Behaviour | Evidence |
|---|---|---|
| Playwright not installed | `validate-visuals.mjs` prints `SKIP -- Playwright is not installed in this environment.` plus the `npx playwright install chromium` remediation, and `process.exit(0)` | `validate-visuals.mjs`; its header states "If Playwright … is not installed, the script exits 0 with a clear SKIP message listing the visuals that must be inspected manually" |
| The HTML file is absent | `SKIP -- html file not found` and exit 0 | same |
| A visual genuinely fails | exit 1 — a generation defect, **not** graceful degradation | `playwright-provisioning.md` "Graceful degradation" |
| CI | The `visual-fidelity` job in `.github/workflows/test.yml` runs `npm ci` in the summarize script directory, `npx playwright install chromium --with-deps`, then the validator; it SKIPs when the artifact is absent | `.aid/knowledge/test-landscape.md` Render-Drift and Generator Self-Tests; `playwright-provisioning.md` |

The escalation when Playwright SKIPs is feature-010's `G1` human visual gate becoming the sole
carrier of visual assurance — the same escalation `/aid-summarize` makes to `V1`, and the same rule
`.aid/knowledge/tech-debt.md` Gotchas states as "Web-output reviews require Playwright: reviewing
`kb.html` or the site by reading HTML/CSS is not a valid review".

### Feature Flow

The canonical-authoring-then-render wiring (C-2), in the order a contributor must perform it. Every
step is a real command from `.aid/knowledge/technology-stack.md` Build/Test Commands or
`.aid/knowledge/test-landscape.md` Test Commands.

**The expected flow is that this feature performs no edit at all.** That is not a placeholder — it
is the outcome D3 argues for, and the flow is written so that the no-op case is the default path and
each edit is reached only by naming its trigger.

1. **Confirm the reuse invocations work as written.** Run each leaf validator against a
   feature-007-shaped `graph.html` with the arguments D5 records, and confirm every check passes
   unmodified:
   ```bash
   bash canonical/aid/scripts/summarize/validate-html-output.sh .aid/knowledge/graph.html --kb-dir .aid/knowledge
   node canonical/aid/scripts/summarize/contrast-check.mjs .aid/knowledge/graph.html
   node canonical/aid/scripts/summarize/validate-visuals.mjs .aid/knowledge/graph.html
   ```
   A failure here is the **trigger check** for the two contingencies, not a defect to work around.
   `S2` failing means FR-18 selected external delivery, so C1 fires; `T2` failing on the live surface
   means feature-002 selected SVG, so C2 fires. Any *other* failure is a defect in `graph.html`, and
   is feature-007's, feature-008's or feature-009's to fix — never a reason to widen a profile.
2. **If, and only if, a contingency fired: amend the one script it names.** Add `--profile` to
   `validate-html-output.sh` (C1) or to `validate-visuals.mjs` (C2), per D3, waiving exactly the one
   named check. `grade-summary.sh` is untouched either way, and neither existing call site is edited.
3. **If step 2 ran, add its test suite and prove the summary path is unchanged.** The golden-output
   pair of D4 — `VP05`/`VP06` or `VV04` — plus `test-guardrails-d012.sh` still passing unmodified:
   ```bash
   bash tests/canonical/test-validate-html-profiles.sh      # C1 only
   bash tests/canonical/test-validate-visuals-profiles.sh   # C2 only
   bash tests/canonical/test-guardrails-d012.sh
   ```
4. **Confirm the degradation path.** With Playwright absent, `validate-visuals.mjs` must SKIP to
   exit 0 with its remediation message (D7), and the run must continue. This is a behaviour check on
   existing code, not a change to it.

Steps 2 and 3 are inseparable: an amended validator without its golden-output suite is exactly the
unproven carve-out D4 exists to prevent, and a plan that schedules them apart should be rejected.

**What follows this feature, and does not belong to it.** The canonical render and count reconcile
are feature-012's Feature Flow; the documentation surfaces, the registration suite and the aggregate
HOME-pinned gate are feature-013's. If neither contingency fires, this feature contributes no file
to the diff — only the evidence, recorded in step 1, that none was needed.

### Layers & Components

#### L1 — moved to feature-012

The new-canonical-files inventory now lives in **feature-012 § L1**. This feature authors no
canonical file. Its entire file surface is conditional and confined to two paths under
`canonical/aid/scripts/summarize/`, plus the two test suites that guard them.

#### L2 — The seam with 010, 012 and 013

Stated identically in the sibling SPECs so the four cannot drift. The original one-sentence form —
"feature-010 owns what the skill does; feature-011 owns how the skill ships and how it borrows" —
splits at the semicolon: **this feature keeps only "how it borrows".**

| Surface | This feature (011) | Other side |
|---|---|---|
| `canonical/aid/scripts/summarize/*` | **Owns every edit**, and owns whether either D3 contingency is triggered at all | feature-010 calls them, unmodified by default |
| `canonical/skills/aid-graph/*`, `canonical/aid/scripts/graph/*`, the templates | Owns nothing | feature-010 (runtime), 003–007 (states), feature-012 (`## References`, `README.md`, the render) |
| The render, the manifests, the count surfaces | Owns nothing | feature-012 |
| Documentation, the registration suite, the ship gate | Owns nothing | feature-013 |
| `test-validate-html-profiles.sh`, `test-validate-visuals-profiles.sh`, the `test-guardrails-d012.sh` pin | **Owns** | — |

The last row is the one worth defending, because it cuts against feature-013's name. Those two
suites are not general test infrastructure; they **are** D4's proofs 3 and 4, they are contingent on
the same triggers as the edits they guard, and separating a carve-out from its guard is the exact
failure mode the carve-out design exists to prevent. A suite that proves a mechanism belongs to the
feature that owns the mechanism.

#### L3 — Tests

Discovered by the `tests/canonical/test-*.sh` glob with no edit to `tests/run-all.sh`
(`.aid/knowledge/test-landscape.md` contracts). Each builds its own fixture under `mktemp -d`,
sources `tests/lib/assert.sh`, uses the `ID + description` assertion-label convention of
`tests/canonical/test-guardrails-d012.sh`, and satisfies A-6 by depending on no work folder.

| Suite | Assertions |
|---|---|
| `tests/canonical/test-validate-html-profiles.sh` (new, **only if C1 fires**) | `VP01` no `--profile` selects `kb-summary` and enforces `S2` plus `NM.1`/`NM.2`/`NM.3`; `VP02` `--profile graph` reports **only** `S2` as `[N/A]`, with a printed reason; `VP03` `--profile graph` still **fails** each of three fixtures — an inline > 100 KB `mermaid` bundle (`NM.1`), a `mermaid.initialize(` call (`NM.2`), and a CDN Mermaid `<script src>` (`NM.3`) — proving D-012 binds both artifacts; `VP04` an unknown `--profile` value exits `2`; `VP05` **golden output** — the no-`--profile` stdout over a fixed fixture is byte-identical to the committed baseline (D4 proof 3); `VP06` the `--profile graph` stdout differs from the default run by **exactly one line** (D4 proof 4) |
| `tests/canonical/test-validate-visuals-profiles.sh` (new, **only if C2 fires**) | `VV01` no `--profile` enforces `T1`–`T4` on every collected visual; `VV02` `--profile graph` reports `T2` as `[N/A]` for the marked live surface only, and `T1`/`T3`/`T4` still fail it when violated; `VV03` an unmarked `.diagram-box` on the same page is still fully `T1`–`T4` checked; `VV04` the two runs' stdout differs by exactly one line (D4 proof 4) |
| `tests/canonical/test-guardrails-d012.sh` (existing, **unmodified**) | Must keep passing. It is the standing pin on `kb.html`'s `S2`/`NM` behaviour and on the presence of those sections in the shared script (D4 proof 2). Its 35 assertions were re-run green after the `NM`-scoring fix, alongside `test-grade-summary.sh`'s 48. |

Two suites that earlier revisions of this SPEC listed here have moved: `test-doc-counts.sh` is
feature-012's count-surface gate, and `test-graph-skill-registration.sh` is feature-013's. The
`gen-reference.test.mjs` edit is gone from this feature entirely — the suite was re-anchored to
derived set comparisons by the defect fix, and its one remaining roster entry is feature-012's.

`.aid/knowledge/test-landscape.md` records prompt-driven skill state machines as "State machines not
machine-tested … Accepted (by design)", so no suite drives the skill end to end; dogfooding plus
review covers that layer, and the suites above cover the deterministic machinery this feature
touches.

### Migration Plan

**One row, and it is contingent.** Every unconditional row an earlier revision carried belonged to
registration or documentation and has moved.

| # | Change | Blast radius | Verification |
|---|---|---|---|
| M1 | **Contingent.** `validate-html-output.sh` gains `--profile` if C1 fires; `validate-visuals.mjs` gains `--profile` if C2 fires (D3). In the expected case neither fires and this feature's diff is empty. | Shared with `/aid-summarize` — the highest-risk change anywhere in this work, which is why it is not made speculatively | `test-validate-html-profiles.sh` `VP01`–`VP06` / `test-validate-visuals-profiles.sh` `VV01`–`VV04`, **and** `test-guardrails-d012.sh` unmodified (D4) |

For the record, so the split leaves no row unaccounted: M2 (the `generate-profile` VALIDATE
re-anchor), M4 (the eleven count surfaces) and M6 (the render) are now **feature-012's M1, M4 and
M5**; M3 (`gen-reference.test.mjs`) is discharged by the defect fix except for one roster entry, now
**feature-012's M3**; and M5 (`reviewer-ledger-schema.md` + `kb-authoring/frontmatter-schema.md`) is
**feature-006's own L3 amendment**, verified by `bash tests/canonical/test-grade.sh` — it was only
ever listed here because this feature used to own the render that followed it.

#### Reported for separate resolution — not fixed here

Each is real and confirmed on disk, and each is about `/aid-summarize`'s scripts or its grading
prose — which is why these three stayed here rather than moving with the split. Identifiers are
preserved so the ledger reads continuously.

**Three findings earlier revisions listed are gone from this table because they are fixed on this
branch**: `U1` (the Node floor, now ≥ 20 — D7), `U2` (`NM` unscored, now scored at 70 pts max — D3),
and the `gen-reference.test.mjs` literals (now derived set comparisons). `U6` and `U7` moved to
feature-012 with the count-reconciliation scope, and `U8` is no longer a report at all — the owner
folded the stale `gen-reference.mjs` comments into feature-012's scope as its migration row `M2`.

| # | Finding |
|---|---|
| U3 | `canonical/skills/aid-summarize/SKILL.md` describes its `AUTO_POOL` as `COV/T1/T2/T3/L1/L2/H1/A1/A2/A3/A4/A5/C1/C2/S2/NM`, but `grade-summary.sh` scores `COV D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2 NM`. `NM` now agrees; `T1`/`T2`/`T3` are still not keys and `D1`/`D2` are still trivially passed, so the prose and the script still disagree on part of the rubric. |
| U4 | `summarize-preflight.sh`'s `**User Approved:** yes` grep is unscoped, and this repository's `.aid/knowledge/STATE.md` carries that literal twice — the KB's approval and the summary's. See feature-010 P2. |
| U5 | `.aid/knowledge/quality-gates.md` Minimum-Grade Thresholds states `.aid/settings.yml` carries an explicit `summary.minimum_grade: A+` override; the file has no `summary:` block and no `review:` block, only a top-level `minimum_grade: A+`. |

**Deliberately left open.** Whether either validator contingency of D3 fires — C1 with FR-18's
delivery decision, C2 with feature-002's renderer decision. Both gates are specified; neither trigger
is this feature's to pull. The expected outcome is that **no shared validator is edited**, and
`/aid-detail` should schedule M1 and its two test suites as conditional work behind D-2 and FR-18
rather than as committed tasks. The third gate an earlier revision left open here — whether an FR-18
build step is adopted — is now feature-012's D3.
