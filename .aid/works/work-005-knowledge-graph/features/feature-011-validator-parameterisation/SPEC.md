# Validator Parameterisation And Toolchain Reuse

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-30 | **Review cycle 1 fix (3 findings).** The theme-divergence check gains an **applicability gate** — it applies only where a block matching a dark selector in force is present, and reports `[N/A]` where none is — after walking it fixture by fixture against the committed `test-contrast-check.sh`: without the gate it would have failed that suite's `:root`-only fixtures, falsifying D5 proof 3, `M1`, `PV10` and Open Item 1's verified-consequence claim. D3, D5 proof 3, `PV11` and Open Item 1 amended accordingly (the cost list now includes the gate's own limit). The Tests preamble's pin enumeration is corrected to **`PV01`, `PV10`, `PV15`, `PV20`** by id — `PV15` was the second unadmitted pin, found by re-auditing every row against the unmodified scripts — and § Figures drops the pin count. AC bullet 6's WebGL limb is removed and routed: no reused validator requests a context | Review |
| 2026-07-30 | **Authored fresh** against the amended REQUIREMENTS, the frozen 001–007 spine and the passed 008/009, per STATE.md **Q26 § Fresh authoring**. Supersedes the 2026-07-28 pre-decision draft in full: that draft was written against the superseded node model and against a packaging question it treated as open, and its two "contingent carve-out" mechanisms (an `S2` waiver, a `T2` live-surface exclusion) are re-derived here from the scripts as read on disk this session — one survives as a contingency, the other is **declined outright**. Three parameterisations the draft did not contain are specified instead: the graph palette's pair set, the **corrected dark-theme extraction** without which that pair set is checked against light values, and the non-vacuity conditions that stop a reused check from passing over an artifact it never reached | /aid-specify |

## Source

- REQUIREMENTS.md §5.5 **FR-12** — reuse `/aid-summarize`'s HTML toolchain **at the script layer**:
  single-file assembly, contrast checking, HTML output validation, Playwright-backed visual
  validation. "Sharing happens through the scripts, not by merging the skills."
- REQUIREMENTS.md §5.6 **FR-17** — the no-runtime-engine rule stays in force for `kb.html` and the
  graph is a documented exception, which is what makes the shared validator a **parameterisation**
  problem rather than a fork.
- REQUIREMENTS.md §5.6 **FR-16 consequence 1** (`:521`–`:536`) — the collision analysis, and its
  closing rule: "In every case `kb.html` must keep all checks unchanged; any exemption is
  per-artifact and parameterised, never achieved by weakening the shared script (feature-011)."
- REQUIREMENTS.md §7 — **C-4** (reuse, do not fork) and **C-5** (Node floor; graceful degradation
  when the browser is not provisioned, *and* its 2026-07-29 extension: a provisioned browser that
  still cannot obtain a WebGL context is a second, distinct failure mode).
- REQUIREMENTS.md §6 — **NFR-1** (WCAG AA) and the SC 1.4.11 obligation that AA carries for the
  graph's marks; **NFR-7**, whose floor is measured "through the same Playwright harness FR-12
  reuses".
- REQUIREMENTS.md §9 — **AC-17** (the pipeline invokes the existing scripts, no duplicated
  assembler/validator logic), **AC-9** (the existing structural and a11y checks pass, scoped to page
  structure and the table view), **AC-6** (runtime prerequisites documented explicitly).
- REQUIREMENTS.md §8 **D-3** — depends on `/aid-summarize`'s script layer remaining stable.
- **feature-007 § Validator surface** (`:1611`–`:1631`) — the check-to-surface mapping AC-9 demands,
  and the routing of two `contrast-check.mjs` parameterisations plus a capture exemption to here.
  **feature-007 D5a** (`:665`–`:715`) — the palette-as-custom-properties contract and the
  verified extractor mechanisms it imposes.
- **feature-002 Open Item 8** (`:1264`–`:1271`) — three parameterisations that may fire, none of them
  the one the draft held in reserve. **feature-002 D1b** (`:449`–`:460`) and **D8** (`:848`–`:893`).
- **feature-009 Open Item 4** (`:649`–`:655`) — the `--kb-dir` help/code discrepancy, routed here.
- **feature-008 § Layers & Components** and its **Open Item 4** — the canvas matches none of
  `validate-visuals.mjs`'s selectors, and option (b) of feature-002's L3 ✗ row is this feature's.

**Dependency position.** Late. Every input this feature reads is either frozen or already passed, and
the artifact it validates is produced by features 007–009 and assembled by feature-010. Nothing here
blocks them: the invocation contract is fixed now so that the scripts are not discovered to be
unsuitable after the page exists.

## Description

`/aid-summarize` already owns a working HTML toolchain — an assembler, an output validator, a contrast
checker and a browser-backed visual gate. None of it should be built a second time, and FR-12 says so.
But every one of those scripts was written for exactly one artifact, and reuse has three sharp edges
that only appear when a second artifact arrives.

The first is the one the requirements anticipated: a guardrail that must keep protecting `kb.html`
while the graph is a documented exception to it. Read against the check bodies rather than against
what an interactive artifact "obviously" needs, that carve-out shrinks to almost nothing — and the
part that does not shrink is contingent on a packaging decision this work has not taken. A waiver
granted for a check that would have passed anyway is not neutral; it is a permanently open door.

The second is a check that cannot see the thing it is supposed to check. The graph carries colour as
meaning, so WCAG's non-text-contrast criterion binds its marks — and the contrast checker is a text
extractor over a fixed list of token pairs, none of them the graph's. Worse, and verified on disk this
session: its dark-theme extraction currently harvests **no custom property at all**, so what it
reports as the dark theme is the light theme re-checked. Adding graph pairs without correcting that
would produce a dark verdict computed against light backgrounds — a check that runs, reports, and
means nothing.

The third is subtler and is the reason this SPEC is written the way it is. Several of these checks
**pass when they reach nothing**: a link check over a page with no links reports every link resolving;
a visual gate over a page with no collected visual reports a trivial pass and exits 0; an unresolvable
colour pair is skipped with a warning that counts as neither a pass nor a failure. Pointing a reused
gate at a new artifact and observing a green run therefore establishes nothing on its own. So this
feature specifies not only what each validator must accept and assert, but what must be **true of the
artifact** for each verdict to carry information — and it makes those conditions assertions rather
than expectations.

What this feature deliberately does not do is make the changes. It fixes the contract: the flag, its
closed value set, the per-profile delta, the proof that the summary path is untouched, and the
boundary around everything else.

## User Stories

- As the **AID methodology owner**, I want the graph checked by the scripts that already check
  `kb.html`, so that one fix improves both artifacts instead of one of two divergent copies.
- As the **AID methodology owner**, I want the no-runtime-engine guardrail to keep binding both
  artifacts, so that the documented exception cannot silently widen into a hole.
- As a **maintainer**, I want `kb.html`'s existing verdicts to be provably unchanged, so that
  adopting the graph cannot break a skill that has nothing to do with it.
- As a **reader who relies on dark mode**, I want the graph's dark palette actually checked, rather
  than its light palette checked twice.
- As a **reviewer**, I want every reused check to fail when it reaches nothing, so that a green
  validation log is evidence rather than an artefact of an empty selector.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-17:** Given the graph's HTML pipeline, when it is reviewed, then it invokes
      `/aid-summarize`'s existing scripts rather than forked copies, and no duplicated assembler or
      validator logic exists.
- [ ] Given the shared validators, when they run over `kb.html` on the default path, then no exemption,
      waiver or graph-specific behaviour reaches them, and their verdicts, emitted text and exit
      statuses are unchanged — with **one** deliberate exception, named in the SPEC and argued with its
      cost: the contrast checker's dark-theme extraction is corrected for both profiles, so `kb.html`'s
      dark block reports the dark values it always should have, and its verdict is re-established rather
      than assumed.
- [ ] Given `graph.html`, when the shared output validator runs, then every check it performs is
      enforced — the no-runtime-engine assertion in all three sub-checks, unconditionally, for both
      artifacts — and any exemption in force is named, reasoned and confined to the single check it
      names.
- [ ] Given the graph palette, when the contrast checker runs over `graph.html`, then every palette
      token is resolved in **both** themes and checked at the 3:1 target SC 1.4.11 sets, the dark
      values checked are genuinely the dark declarations, and a token that fails to resolve is a
      failure rather than a skipped warning.
- [ ] Given any reused check whose input set can be empty, when it runs over `graph.html`, then a
      zero-sized input set is reported as such and does not produce a pass.
- [ ] Given an environment with no Playwright, or a missing artifact, when validation runs, then it
      degrades with an actionable message, the skip is recorded rather than silent, and the run
      continues (**PV19**). **C-5's WebGL-context mode is deliberately not a limb of this criterion**
      — no reused validator ever requests a context, so none of the three can observe it; it is routed
      in the boundary table, and **C3** is this feature's only WebGL-adjacent mechanism.
- [ ] Given an unrecognised profile value, when any parameterised script is invoked, then it exits 2
      with a usage error naming the closed set of values, so a third policy cannot be introduced at a
      call site.
- [ ] Given each parameterised script, when its `--help` output and header comment are read, then
      every flag they document behaves as documented.

---

## Technical Specification

> **Grounded in the scripts as read on disk 2026-07-30**, at
> `canonical/aid/scripts/summarize/`: `validate-html-output.sh`, `contrast-check.mjs`,
> `validate-visuals.mjs`, `assemble.sh`, `stale-check.sh`, `grade-summary.sh`; in
> `canonical/aid/templates/knowledge-summary/component-css.css`; in the shipped
> `.aid/knowledge/kb.html`; in `tests/run-all.sh`, `tests/canonical/test-contrast-check.sh`,
> `tests/canonical/test-guardrails-d012.sh` and `.github/workflows/test.yml`; and in the KB's
> `coding-standards.md` and `test-landscape.md`. Every line number below was verified at the
> `canonical/` path, never at a `.claude/` or `profiles/` render — those are different artifacts and
> one is excluded from enumeration by design.
>
> **No quantity here is a measurement** (§ Figures).

### The parameterisation boundary — what this feature does not do

Stated first, because a reader of a validator SPEC will otherwise infer scope from what "validation"
usually covers.

| It does not | Because | Owner |
|---|---|---|
| Edit any script | This SPEC fixes the contract each script must satisfy. The edits are `/aid-execute`'s | — |
| Decide the packaging, or whether a bundle is inlined or vendored | The `S2` and `NM.1` contingencies are keyed on that decision and this feature pulls neither trigger | FR-18, feature-012 |
| Decide whether a WebGL context or a screenshot is obtainable headless — **including C-5's WebGL-context failure mode**, which no reused validator can observe: `validate-visuals.mjs`'s whole browser surface is `chromium.launch` (`:185`), `page.goto` (`:204`) and collections over `.diagram-box`, `.infographic` and top-level `<svg>` (`:303`–`:304`, `:328`), none of them a canvas | Stage 1's three-level verdict; two of this feature's mechanisms are contingent on it | feature-002 |
| Register a script, touch an install or emission manifest, or run the profile render | Registration and count reconciliation | feature-012 |
| Wire a CI lane, place a cross-feature assertion, or write ship-time documentation | Tests-and-docs, and aggregate lane wiring | feature-013 |
| Grade anything, or assign a severity to a failing check | The graph's gate is a sibling orchestrator with its own rubric | feature-010 |
| Assert lens parity across the two renderings (**NFR-3**), a settled reduced-motion render (**NFR-4**), or a frame-rate floor (**NFR-7**/**AC-6a**) | **No reused validator reaches any of them.** They are store-level and in-page properties, asserted by feature-007's `GV*`, feature-008's `GC*` and feature-002's harness — not by a text grep or by the visual gate | features 002, 007, 008 |
| Assert anything about the canvas's DOM | AC-9 as scoped excludes it; the canvas carries a text alternative only | feature-007, feature-009 |
| Read `relationships.md`, or introduce any second input path | **AC-10.** No validator reads the table; each reads the emitted page | feature-007 |
| Synchronise a check against the running simulation | The page is asserted at `domcontentloaded` (`validate-visuals.mjs:204`) while the graph is still moving. Harmless because no reused check reads the canvas — and a precondition for any future check that does | feature-002 D1b |
| Decide which check-to-surface mapping AC-9 requires | feature-007 § Validator surface is the authority; this SPEC consumes it and adds only the conditions under which each verdict carries information | feature-007 |
| Validate KB content quality, or fail a run because gaps exist | §4 Out of Scope, FR-25/FR-28. Every check here is over the **emitted page**, never over the Knowledge Base | discovery |

### Data Model

The "model" here is the invocation contract: one flag, one closed value set, three per-script deltas,
and the properties that keep a delta from becoming a weakening.

#### D1. The profile contract — one shape across all three scripts

```
<script> <artifact-path> [--profile kb-summary|graph] [<existing flags…>]
```

| # | Property | Why, and what it forecloses |
|---|---|---|
| 1 | **The flag's absence selects `kb-summary`, and that path is byte-identical — with exactly one named exception.** The two existing call sites are not edited: `grade-summary.sh:263` runs `bash "$SCRIPT_DIR/validate-html-output.sh" "$HTML"` and `grade-summary.sh:348` runs `node "$SCRIPT_DIR/contrast-check.mjs" "$HTML"`, each with the artifact path alone. **The exception** is the corrected dark extraction and the theme-divergence line in `contrast-check.mjs`, which apply to both profiles by decision (D3; Open Item 1) — so that script's default-path baseline is **re-taken** and its substance asserted instead (D5 proof 4, **PV11**). No other default-path output changes | A call-site change smuggling the graph's policy into the summary path. Byte-identity, not merely verdict-identity, because `grade-summary.sh` derives `S2`, `NM`, `L1`, `L2`, `C1` and `C2` by grepping the emitted text (`:316`, `:323`, `:326`–`:327`, `:355`–`:368`) — so a wording change can move a grade without moving a verdict |
| 2 | **The value set is closed and lives once per script, in its header.** An unrecognised value exits **2** — usage error, per `coding-standards.md:221` and, for the Node scripts, `:186` | A third policy introduced at a call site. Widening requires editing the table, which is a reviewable diff |
| 3 | **The active profile is printed exactly when the flag is passed explicitly.** With the flag absent, nothing is added to stdout (property 1) | An installed copy predating the flag **silently ignoring** it. `contrast-check.mjs` today parses no flags at all — it reads `args[0]` and ignores the rest (`:10`–`:16`) — so without a printed profile line a stale copy would validate the wrong pair set and pass. The line is what makes the mismatch detectable (**PV03**) |
| 4 | **A delta names checks, never categories.** No profile waives a script, a severity band or a check family | The widening the 2026-07-28 draft's own review caught once: a waiver whose stated premise was false and which, granted, would have re-opened the guardrail it was excepted from |
| 5 | **A waived check prints why.** `S2. Offline render [N/A] external assets permitted for profile 'graph'`, never a silent pass | A policy in force that is invisible in the validation log — which is also part of how AC-6's "prerequisites documented explicitly" is discharged at validation time |
| 6 | **`graph.html` is validated only under `--profile graph`**, once the parameterisation exists. The default profile's behaviour is specified and asserted over fixtures and over the shipped `kb.html`; this SPEC asserts nothing about the default profile applied to the graph artifact. The one exception is the **pre-change trigger reading** (§ Feature Flow step 1), which runs before the flag exists and is a diagnostic, not a gate | A reader inferring that the two profiles are interchangeable views of one artifact |

#### D2. `validate-html-output.sh` — read check by check against `graph.html`

The verdicts below are derived from the check bodies, not from what the graph is assumed to need.

| Check | What the code actually tests | Verdict for `graph.html` |
|---|---|---|
| `H1` | `tidy` if present (`:105`), else `npx html-validate` (`:119`–`:124`), else a four-grep regex fallback for doctype/`<html>`/`<head>`+`<body>`/charset (`:137`–`:173`) | **Passes**, and the mode is recorded. See the limitation below: a fallback `H1` pass is not a validity verdict |
| `A1.1`–`A1.6` (`:184`–`:189`), `A2.1`–`A2.4` (`:196`–`:199`), `A3` (`:208`–`:220`), `A4.1` (`:234`), `A5.1` (`:241`) | greps for `lang`, `header role="banner"`, `main`, `nav`, `footer`, `title`; the four lightbox ARIA attributes; `trapFocusOnTab` + `lastFocused.focus()` + an Escape handler; the reduced-motion media query; `:focus-visible` | **Pass by construction.** feature-007 reuses `component-css.css` and `lightbox.js` verbatim and ships exactly one dialog — the reused lightbox — so A2 and A3 grep unforked code |
| skip-link, `<noscript>`, `color-scheme` (`:248`–`:250`) | three greps | **Pass** — feature-007's Component breakdown emits all three |
| `S2` (`:253`–`:264`) | `<script[^>]+src="https?://` and `<link[^>]+href="https?://` | **Passes under the reference local-vendored layout.** Fails only if the packaging genuinely references an external origin — contingency **C1** |
| `NM.1` (`:293`–`:311`) | awk, one rule, needing **all three** of: a non-`text/markdown` inline `<script>`, a body over 100 000 bytes, and the literal token `mermaid` in it | **Passes unmodified.** A `d3-force`/PixiJS bundle contains no such token however large it is; the size trigger alone fires nothing. Whether the token appears in the vendored bytes is a grep feature-002 D4 owes |
| `NM.2` (`:319`), `NM.3` (`:325`) | `mermaid\.initialize\(`; a `<script src>` whose URL contains `mermaid` | **Pass unmodified** |
| `L1` (`:345`–`:378`) | every `href="#X"` against the page's own `id="X"` set | **Passes** — see the vacuity condition below |
| `L2` (`:386`–`:404`) | every `href="./X.md"`, `sort -u`, each resolved as `"$HTML_DIR/$mdlink"` | **Passes.** The basis is the artifact's own directory (`HTML_DIR=$(dirname "$HTML")` at `:62`, consumed at `:391`), and `graph.html` ships beside its targets |

**All three `NM` sub-checks stay enforced under both profiles, unconditionally, and no profile may
waive one.** The reasoning is the code's: they are keyed on a literal token, so a non-Mermaid renderer
passes them as written and a waiver buys nothing — while granting one would leave `NM.3` as the sole
guard against an inline Mermaid engine in `graph.html`, which is precisely the decision the checks
exist to enforce. **PV06** asserts all three fire under both profiles.

**Two verdicts above are vacuous when the artifact is empty, and that is the interesting part.** `L1`
reports `✅ L1. $ANCHOR_TOTAL/$ANCHOR_TOTAL anchor links resolve` (`:373`) and `L2` reports the same
shape (`:399`) — so **`0/0` prints as a pass**. Under `--profile graph`, a zero-sized input set is
therefore reported `[VACUOUS]` and fails; the default profile keeps today's wording and verdict
(**PV08**), because changing it would alter text `grade-summary.sh:326`–`:327` greps. The graph's
`L2` input set is not merely non-empty but **known**: the footer's `./relationships.md` and
`./external-sources.md` plus `<noscript>`'s `./INDEX.md`, which the script's `sort -u` collapses to a
set (feature-007's Footer and `<noscript>` rows). **PV05** asserts the set, not its size.

**Decision — the `--kb-dir` discrepancy is closed by correcting the documentation, and the flag's
behaviour is left exactly as it is.** The code resolves relative `.md` links against `HTML_DIR`
(`:62`, `:391`); `KB_DIR` is assigned at `:35`/`:43` and read **only** by `L2`'s progress line at
`:384`. The `--help` text (`:9`) and the header comment (`:28`) both claim the flag sets the
resolution basis. Three grounds for correcting the text rather than the code:

1. **The code's behaviour is the correct one, for both artifacts.** Resolving against the emitting
   file's own directory is what a browser does with a relative `href`, and it is what makes the check
   true for a fixture assembled under `mktemp -d`.
2. **Wiring the flag would make `L2` weaker.** A basis supplied by the caller can point at a
   directory where the target happens to exist, turning a broken link in the delivered tree into a
   pass. That is a way to make a check vacuous on demand, which is the opposite of what this feature
   is for.
3. **Nothing passes the flag, and the graph will not either.** The only caller today is
   `grade-summary.sh:263`, which omits it; the graph's invocation is the artifact path plus
   `--profile graph` and no `--kb-dir` (§ Feature Flow step 1). So wiring it would change behaviour for
   no caller while creating a way to weaken `L2` for a future one.

The flag is therefore **retained** (removing it would be a breaking CLI change for no gain) and
documented truthfully: accepted for compatibility, echoed in `L2`'s progress line, and setting no
resolution basis. `coding-standards.md:64` requires the header block to state Purpose/Usage/Exit
codes, so a header that describes a flag it does not implement is a defect against a standard this
repository already holds. **PV09** pins the wording to the behaviour, so the two cannot drift again.
This discharges **feature-009 Open Item 4** and the documentation half of feature-007's routing.

**A stated limitation, not a defect.** `H1`'s strength depends on what is installed: with neither
`tidy` nor `html-validate` reachable it degrades to four greps and still prints a pass line
(`:167`–`:169`). The mode is emitted (`:107`, `:140`) and must be carried into the run's validation
report, so a fallback pass is never read as a validity verdict. What a gate does with that
information is feature-010's.

#### D3. `contrast-check.mjs` — the palette check, and the three mechanisms that make it silent

The obligation is **SC 1.4.11 Non-text Contrast, Level AA**: the graph's marks carry node kind and
relationship category as colour (NFR-5), so they are "parts of graphics required to understand the
content" and must clear **3:1** against adjacent colours. NFR-1 sets AA, and REQUIREMENTS declines to
rest colour conformance on the table as the alternate version. feature-007 D5a owns the declaration;
this feature owns the checker.

**Three verified mechanisms, each of which makes a wrong palette pass rather than fail.**

| # | Mechanism, verified | Consequence |
|---|---|---|
| 1 | An unresolvable pair prints `⚠️ … cannot resolve colors` and `continue`s (`:126`–`:129`) — counted as neither pass nor failure, and invisible to `grade-summary.sh:355`–`:368`, which greps for `FAIL`/`fail` | A pair list that names a token nobody declared is **silently incomplete**. This is the exact failure this SPEC's non-vacuity rule exists to prevent, sitting in the script it most needs to be absent from |
| 2 | `extractVars` matches with `String.prototype.match` and **no `g` flag** (`:21`–`:22`), so only the **first** block per selector is read, and returns `{}` when the selector is absent (`:23`) | Verified in the assembled page: the `html[data-theme="dark"]` call wins `component-css.css:4`'s `color-scheme: dark` block (assembled at `kb.html:19`), which declares **no** custom property. Since `dark = { ...light, ...darkVars }` (`:40`), today's dark run re-checks the **light** values. Confirmed by running the script over the shipped `.aid/knowledge/kb.html` this session: the dark block's reported ratios are identical to the light block's, pair for pair |
| 3 | The variable-name charset is `[a-z-]+` (`:26`) — no digits, no underscore, no uppercase | A numbered token is invisible and silently unchecked. feature-007 D5a already binds the palette to this charset; **PV13** re-asserts it from the checker's side |

**The correction, and why "extract all occurrences and merge" is the wrong fix.** `component-css.css`
carries three blocks matching the **dark** selector, and only one of them is the palette: `:4`'s
`color-scheme: dark` declaration, which declares no custom property; the theme-variable block at `:37`;
and a **third at `:588`, inside the `@media print` block opened at `:575`**, which re-declares every
dark token with the **light** values so print output renders light. Merging all
occurrences in document order would let the print values win, and the harm is not the obvious one:
there is no working dark check to corrupt, so merge-all would leave the existing hole open *and* open
it for the graph's palette.

**The rule adopted instead:** for each named selector, extract the **first matching block that
declares at least one custom property**; if none does, the empty map, unchanged. Verified
consequences, both artifacts:

- On the shipped `kb.html` the **sole** block matching `/:root\s*\{/` is the `color-scheme` one at
  `kb.html:17`, which declares no custom property — so the `:root` fallback call stays the empty map it
  already produces. **Byte-identical.**
- The dark call moves from the `color-scheme` block to the theme-variable block
  (`component-css.css:37`, assembled at `kb.html:52`) — the intended correction — and the
  `@media print` block (`component-css.css:588`, assembled at `kb.html:601`), occurring later, cannot
  win.
- On `graph.html` the `:root` fallback call additionally reaches the graph's own light block, whose
  selector `html:root {` matches `/:root\s*\{/`. Harmless and stated: no pair in the default set names
  a graph token, the block is extracted by name under `--profile graph` anyway, and the merge order
  (`light = { ...:root, ...':root, html[data-theme="light"]', ...html:root }`) leaves every chrome
  token's value coming from `component-css.css`.

**And a guard, because the rule above is necessary but not sufficient.** A single emitted check —
**theme divergence** — asserts that the dark map differs from the light map on at least one token both
declare, **wherever at least one block matching a dark selector in force is present**. Where none is,
`darkVars` is `{}` by construction, `dark ≡ light` is the correct reading and there is nothing to
diverge from, so the check reports `[N/A]` with its reason instead of failing — the discriminator is
the selector's **presence in the source**, not the emptiness of the extracted map, which is what keeps
every `:root`-only fixture in `test-contrast-check.sh` passing (D5 proof 3). The differing-token
property fails under **both** adversaries at once: an extraction that harvests nothing yields
`dark ≡ light` by `:40`, and one that wins the `@media print` block yields it **by construction**,
since that block's values *are* the light palette. It is emitted at every run — `[N/A]`, pass or fail
— rather than living only in the suite, so the hole cannot silently reopen.

**Three details of that check are load-bearing against `grade-summary.sh`, and are specified, not
left to an implementer.** It is emitted **after** the dark theme block, because
`grade-summary.sh:363` derives `C2` from `sed -n '/\[dark theme\]/,$p'`; its failure line carries the
token **`FAIL`** that `:364` greps for and no other line it emits does; and a divergence failure
makes the script **exit 1** and print the failure summary rather than `All contrast checks passed`,
because `:366`–`:368` restores both `C1` and `C2` to `pass` on that literal and `:348`'s success
branch never reaches the per-block greps. Together they demote `C2` on a broken dark extraction.

**The graph profile's delta.**

| Element | `kb-summary` | `graph` |
|---|---|---|
| Selector blocks | the three existing calls (`:34`–`:36`) | plus **two named additional selectors** — `html:root` for light and `html[data-theme="dark"]:root` for dark (feature-007 D5a). Both occur exactly once, neither inside an at-rule, and neither is reachable by the existing calls: `html\[data-theme="dark"\]\s*\{` does not match `]:root {`, and the light call is shadowed by `component-css.css:2` because `match` returns the first occurrence and `component-css.css` is inlined ahead of `graph-css.css` |
| Pair set | the list at `:97`–`:109`, every pair at its own `target: 4.5` | that list **unchanged and still at 4.5**, **plus** the graph pairs at **3.0** |
| Graph pairs | — | the cross product of {every `--gk-*` token in feature-007 D5c's kind table, every `--gc-*` token in its D5b holder table} × {`--bg`, `--bg-elev`} |
| Unresolvable pair | `⚠️` + `continue`, unchanged (pinned by `test-contrast-check.sh:81`–`:82`) | **a failure**, naming the token and the pair |
| Redeclaration | — | a token named by the existing pair list, declared in either added block, is a **failure** |

Four notes on that pair set, each a decision rather than an inheritance:

1. **Two backgrounds, deliberately stronger than the criterion requires.** SC 1.4.11 binds a mark
   against its actual adjacent colour, and neither feature-007 nor feature-008 fixes a dedicated
   surface token — the graph region sits on the page surface or on an elevated card, and
   `graph-css.css` consumes existing chrome tokens for chrome. Checking each palette token against
   **both** removes the dependency on a CSS detail no frozen SPEC states, and it cannot be satisfied
   by choosing a convenient background. If feature-007 later declares one surface token, the pair set
   narrows to it; that is recorded as the fallback rather than chosen (Open Item 5).
2. **Marks are not checked against each other.** Distinguishing two kinds or two categories is SC
   1.4.1, carried by glyph and line style (NFR-5; feature-007 D5b's within-colour uniqueness rule).
   Asserting pairwise mark contrast would over-constrain the palette against a criterion that does
   not ask for it.
3. **The chrome tokens the graph reuses for marks need no new pair.** `--text-dim` on `--bg-elev` and
   `--accent` on `--bg-elev` are already in the list at `:97`–`:109` at a **higher** target, so a
   graph pair for either would be strictly weaker than what already runs.
4. **The set is cited, never counted.** The tokens are whatever feature-007 D5b and D5c name; the
   pair set is generated from those tables and from the two background tokens. A numeral here would
   go stale the moment either table moves.

**Argument parsing has to be added, and three pinned behaviours must survive it.** `contrast-check.mjs`
has no parser: `args.length < 1` exits 2 with a usage line (`:10`–`:14`) and `args[0]` is read as the
path (`:16`). `test-contrast-check.sh` pins no-args → exit 2 with "Usage" (`:56`–`:57`), a missing file
→ non-zero (`:60`), and the unresolvable-skip behaviour (`:81`–`:82`). All three hold unchanged
(**PV10**).

#### D4. `validate-visuals.mjs` — what is collected, and the two paths that pass without checking

**The collector, verified.** `.diagram-box` and `.infographic` containers (`:303`–`:304`), then every
top-level `<svg>` not inside one of them (`:328`). **A `<canvas>` matches none of the three.** That is
load-bearing in two directions: feature-008's text-alternative route depends on the live surface not
being collected, and the T2 sibling-`<g>` overlap exclusion the 2026-07-28 draft held in reserve is
therefore unnecessary.

**Decision — the reserved T2 live-surface exclusion is declined outright, not held.** An unexercised
waiver in a shared script is a permanently open door, and the graph has no element that needs it: the
one authored visual on the page is the legend, a `.diagram-box` (feature-007's Component breakdown),
which stays fully inside the gate. **PV18** asserts no such exclusion exists under either profile and
that an overlapping `.diagram-box` still fails T2 — so a speculative waiver is a test failure rather
than dead code.

| Check | Threshold, verified | Applied to `graph.html` |
|---|---|---|
| `T1` | rendered font-size ≥ `--min-font-size`, default 10 (`:13`, `:64`), and not zero-height-clipped (`:489`–`:496`) | **Enforced**, no override passed. feature-008 takes the same default as its own label-legibility reference |
| `T2` | sibling-child overlap ≤ `OVERLAP_TOLERANCE` (`:94`); for an `<svg>`, sibling `<g>` only, trivially passing below two groups (`:350`–`:360`) | **Enforced on every collected visual, under both profiles** |
| `T3` | non-trivial bounding rect (`:482`) | **Enforced.** See the container consequence below |
| `T4` | no horizontal overflow of its own container at each `OVERFLOW_VIEWPORTS` width (`:95`, `:502`–`:508`) | **Enforced.** The widths are a module constant with **no flag**, so no graph-specific viewport is available and none is requested — the same two widths feature-007 and feature-009 state their responsive contracts against |

**Two vacuous-pass paths, and how each is closed.**

1. **Zero collected visuals exits 0 as a "trivially passed" gate** (`:464`–`:471`). Under
   `--profile graph` an empty collected set is a **failure**; the default profile is unchanged
   (**PV17**). Positively, **PV16** asserts the collected set over a generated `graph.html` is
   non-empty, contains the legend, and contains **no** entry for the canvas.
2. **A missing artifact exits 0 with a SKIP** (`:102`–`:108`), as does an unimportable `playwright`
   (`:119`–`:146`). Both are correct C-5 degradation and neither is changed. What this feature
   requires is that the skip be **recorded** in the run's report rather than absorbed as a pass
   (**PV19**), because a lane that always skips looks exactly like a lane that always passes — see
   Open Item 2, where that is not hypothetical.

**A container consequence worth stating, because it constrains the page rather than the script.** The
zero-bbox skip at `:340` is in the `<svg>` branch **only**; the container branch (`:309`–`:325`) has
none. So a `.diagram-box` that is not laid out at load — one that exists only inside a closed dialog,
say — is collected with zero dimensions and **fails T3**. The legend must therefore be in the page,
with the reused lightbox enlarging it rather than containing it, which is what feature-007 already
specifies. **PV16** asserts the legend's dimensions are non-zero, so the obligation is checked rather
than assumed.

**The three contingent parameterisations, all `graph`-only.** Collected here so they sit together —
one is on `validate-html-output.sh` and two on this script. Each is specified now so the trigger does
not arrive without its guard, and each is asserted **absent** until its trigger fires, so an
unrequested exemption is a test failure rather than dead code (**PV20**).

| # | Contingency | Trigger | Mechanism |
|---|---|---|---|
| C1 | **`S2` reported `[N/A]` with its printed reason** on `graph.html` | FR-18/feature-012 select packaging that genuinely references an external origin | `validate-html-output.sh --profile graph`. **Exactly one** check's line changes; every other check, including all of `NM`, stays identical between profiles. Cross-checked against the page's own emitted prerequisites (**PV07**), so the trigger is mechanical rather than a claim |
| C2 | **Capture exemption** — the live surface is exempt from screenshot-based checking, with an in-page `readPixels` assertion substituted and the human visual gate carrying the rest | feature-002 Stage 1 returns `L1 ✓ L2 ✓ L3 ✗` and its report recommends its option (b) | `validate-visuals.mjs --profile graph` only; `kb.html`'s per-visual lines stay byte-identical. This is feature-002 D1a's option (b) and feature-008 Open Item 4's routing |
| C3 | **Launch-flag change** — additional `chromium.launch` arguments to obtain a WebGL context at all | Stage 1 establishes that a flag is necessary | `validate-visuals.mjs --profile graph` only. The `kb-summary` argument list (`:185`–`:188`) is unchanged, source-level and behaviourally |

If the reference local-vendored layout holds and Stage 1 returns `L1 ✓ L2 ✓ L3 ✓`, **none of the three
fires** and this feature's diff is confined to the contrast checker, the two vacuity conditions and the
`--kb-dir` documentation.

#### D5. Proving `kb.html` is unchanged

| # | Proof | What it rules out |
|---|---|---|
| 1 | Neither existing call site is edited (`grade-summary.sh:263`, `:348`), and the flag's absence selects `kb-summary` | The graph's policy reaching the summary path |
| 2 | `tests/canonical/test-guardrails-d012.sh` passes **unmodified** — its `C1b` (`:79`–`:80`), `C2/C3c` (`:128`–`:130`), `C2/C3d` (`:134`), `C2/C3e` (`:143`), `C2/C3f` (`:153`), `NM-a` (`:165`) and `NM-e` (`:195`) | Regression of the `S2`/`NM` guardrails, of the hermetic-render route, or of `assemble.sh`'s documented defaults. It builds its own fixtures inline, so it depends on no work folder (**A-6**) |
| 3 | `tests/canonical/test-contrast-check.sh` passes **unmodified**, `CC01`–`CC09b` — established fixture by fixture rather than asserted: its `pass-hex6`, `pass-hex3`, `pass-rgb`, `fail` and `skip` fixtures declare only `:root`, so divergence is `[N/A]` on each — the one added line — and every exit status and summary line stands (`CC03b`'s `All contrast checks passed` on the passing ones, `CC06b`'s failure summary on `fail`); `dark-fail` declares a dark block whose values differ, so divergence passes there and its exit 1 still comes from the contrast failure; and the shipped `kb.html` satisfies divergence under the corrected rule | The added parser breaking the exit-code contract, the unresolvable-skip behaviour being changed for the default profile, and — the case this proof was re-derived to catch — the divergence check failing a fixture that has no dark theme to diverge from |
| 4 | **Golden default output** over committed fixtures: the full stdout and exit status of each script with no `--profile`, before and after (**PV01**) | Any change to the summary path's reported text or tally, not merely its verdict |
| 5 | **Confined delta** under `--profile graph`: for each contingency, the diff against the same fixture's default run is confined to the single check the contingency names (**PV07**, **PV20**) | A profile quietly waiving a second check — which proofs 1–4 would all survive |

Proofs 4 and 5 are the load-bearing pair. Two of the changes this SPEC specifies are deliberately
**not** covered by proof 4, and each is named as such: the corrected dark extraction and the theme
divergence check apply to **both** profiles, so `kb.html`'s dark block reports different ratios and
gains a line. Proof 4's baseline is re-taken for those two, with the substance asserted instead —
`kb.html` still exits 0, still reports no `FAIL` in either theme block, and now satisfies theme
divergence (**PV11**). The reasoning is in Open Item 1.

#### D6. The scripts deliberately not reused, and why each

| Script | Disposition | Verified reason |
|---|---|---|
| `assemble.sh` | **Reused, unmodified** | All three paths are flags (`:35`–`:39`, `:49`–`:51`) and its defaults (`:43`–`:45`) are untouched, so `test-guardrails-d012.sh`'s `C1b` still holds. An unknown argument exits 2 (`:56`–`:60`). Nothing to parameterise |
| `stale-check.sh` | **Not reused, and not parameterised here** | It has **no argument parser at all**, and hardwires `KB_DIR` (`:21`) and `HTML_FILE=".aid/knowledge/kb.html"` (`:24`), reading `## Summarization History` (`:53`) and `summary_approved` (`:99`). So passing it a path is **silently ignored** and an apparent reuse would report staleness for the wrong artifact — a pass that means the opposite of what it says. The graph's staleness is over FR-11's own input set and is feature-010's |
| `grade-summary.sh` | **Not reused** | It hardwires `KB_DIR` (`:65`) and its pool (`:18`, `:201`) is centred on `COV`, resolved-doc-set coverage of `kb.html`; importing that would grade the KB's completeness, which FR-28 forbids. Reuse happens one layer down, at the leaf validators where every check lives — which is exactly AC-17's test, satisfiable by inspection: the graph's gate contains no check body because it invokes the same leaves |

### Feature Flow

The order a contributor performs this in. **The expected path is that no waiver is added**, so the
no-op case is the default and each contingency is reached only by naming its trigger.

1. **Take the trigger reading, with the scripts exactly as they are today.** Against a
   feature-007-shaped `graph.html`, and with **no** flag — the parameterisation does not exist yet,
   which is why this is the one unparameterised run over the graph artifact and why it is a diagnostic
   rather than a gate (D1 property 6):
   ```bash
   bash canonical/aid/scripts/summarize/validate-html-output.sh .aid/knowledge/graph.html
   node canonical/aid/scripts/summarize/contrast-check.mjs      .aid/knowledge/graph.html
   node canonical/aid/scripts/summarize/validate-visuals.mjs    .aid/knowledge/graph.html
   ```
   No `--kb-dir` here or anywhere, on D2's reasoning. Record every verdict, and the emitted `H1` mode.
2. **Read a failure as a trigger check, not as an obstacle.** `S2` failing means the packaging
   references an external origin, so **C1** fires. A missing WebGL context or a blank capture is
   feature-002 Stage 1's verdict, so **C2** or **C3** fires. **Any other failure is a defect in
   `graph.html`** and belongs to feature-007, 008 or 009 — never a reason to widen a profile.
3. **Amend the contrast checker** — the only unconditional behaviour change here: the corrected block
   selection, the theme divergence check, the argument parser, the two added selectors, the graph pair
   set at 3:1, the fail-on-unresolvable and redeclaration guards (D3).
4. **Add `--profile` and its vacuity condition to the other two scripts** — the flag itself is
   unconditional on all three, because each vacuity condition is per-profile (D2's `[VACUOUS]` report;
   D4's empty-collection failure) — and **correct the `--kb-dir` documentation**.
5. **If and only if a contingency fired, add the one delta it names** inside `--profile graph`, waiving
   exactly the one named check with its printed reason.
6. **Land the suite in the same change.** Steps 3–5 and the suite are inseparable: an amended
   validator without its assertions is the unproven carve-out D5 exists to prevent, and a plan that
   schedules them apart should be rejected.
7. **Re-run under the invocation feature-010 will use** — the artifact path plus `--profile graph` on
   each of the three — and confirm every verdict from step 1 is unchanged except where a delta was
   deliberately added, and that no verdict is now vacuous.
8. **Confirm the degradation paths behave** with `playwright` absent and with the artifact absent — a
   behaviour check on existing code, plus the recording obligation (D4).

### Layers & Components

**This feature authors no new canonical file.** Its whole file surface is three existing scripts under
`canonical/aid/scripts/summarize/` and one new suite:

```
canonical/aid/scripts/summarize/
├── contrast-check.mjs         # --profile + parser; the whole of D3, unconditional
├── validate-html-output.sh    # --profile + the L1/L2 vacuity report + the --kb-dir doc fix;
│                              #   the S2 delta inside that profile only if C1 fires
└── validate-visuals.mjs       # --profile + the empty-collection failure + the recorded skip;
                               #   a capture exemption or launch flag inside it only if C2/C3 fires

tests/canonical/
└── test-validator-profiles.sh # new — every PV assertion
```

Authored **once in `canonical/`** and rendered to every host profile by the existing generator (C-2);
the rendered copies are build output and are never hand-edited. The render itself, the manifests and
the count surfaces are **feature-012's** — nothing here runs the generator.

**One suite, not three.** The parameterisation is one mechanism with one profile table across three
scripts, and its sharpest assertions are cross-script (D1's uniform properties). Splitting per script
would separate assertions that must agree. It is discovered by the `tests/canonical/test-*.sh` glob
(`tests/run-all.sh:112`; `test-landscape.md:113`) with no runner edit, builds its own fixtures under
`mktemp -d`, sources `tests/lib/assert.sh`, and uses the `ID + description` label convention
`test-guardrails-d012.sh` follows — so it satisfies **A-6** by construction. Aggregate CI lane wiring
and any cross-feature assertion placement are **feature-013's**.

### Migration Plan

| # | Change | Blast radius | Verification |
|---|---|---|---|
| M1 | **`contrast-check.mjs`** — corrected block selection, theme divergence check, argument parser, two added selectors, graph pair set at 3:1, fail-on-unresolvable and redeclaration guards | Shared with `/aid-summarize`. The dark correction and the divergence check reach `kb.html`'s reported output — the one deliberate departure from byte-identity, argued at Open Item 1 | **PV01**–**PV03**, **PV10**–**PV15**; `test-contrast-check.sh` unmodified |
| M2 | **`validate-html-output.sh`** — `--profile` added; `[VACUOUS]` report for an empty `L1`/`L2` input set inside `--profile graph`; `--help` (`:9`) and header comment (`:28`) corrected | Graph-only for behaviour; documentation-only for the summary | **PV04**–**PV06**, **PV08**, **PV09**; `test-guardrails-d012.sh` unmodified |
| M3 | **`validate-visuals.mjs`** — `--profile` added; empty-collection failure and the recorded skip inside `--profile graph` | Graph-only | **PV16**–**PV19**; `test-guardrails-d012.sh` unmodified |
| M4 | **Contingent.** `S2` `[N/A]` profile (**C1**); capture exemption (**C2**); launch flag (**C3**) | The highest-risk changes in this feature, which is why none is made speculatively | **PV07**, **PV20**, and the confined-delta proof (D5 proof 5) |

`/aid-detail` should schedule M1–M3 as committed work and **M4 as conditional**, behind FR-18's
packaging decision and feature-002's Stage 1 verdict.

### Tests

All assertions carry the prefix **`PV`** (parameterised validators), which is unused elsewhere in this
work — features 006, 007, 008 and 009 use `GL`, `GV`, `GC` and `TV`. They live in
`tests/canonical/test-validator-profiles.sh`.

**Every assertion pins its quantifier to something the artifact must contain.** **PV01**, **PV10**,
**PV15** and **PV20** are **pins** — invariance claims whose subject *is* "nothing changed", so a
do-nothing implementation passing one is correct behaviour and its adversary is a regression. That
enumeration is exhaustive, taken row by row against the scripts as they stand: PV15 qualifies because
`contrast-check.mjs` ignores an unrecognised argument (`:10`–`:16`), PV20 because each of its clauses
holds until its trigger fires (D4's contingency table). Every other assertion below is written so both an
implementation that does nothing and one that is fully populated but wrong fail it. The vacuous-pass
paths this SPEC identified in the three scripts — a zero-sized `L1`/`L2` input set (D2), an unresolvable
colour pair and a dark map identical to the light one (D3), an empty collected visual set and a skip
indistinguishable from a pass (D4) — are each closed by a named assertion rather than by a caution.

| ID | Assertion | Criterion |
|---|---|---|
| **PV01** | *(pin)* with no `--profile`, each of the three scripts' full stdout and exit status over each committed fixture equals the baseline captured before the change — for `contrast-check.mjs`, with the dark theme block's ratios and the divergence line re-baselined and identified as such (D5 proof 4) | D5 |
| **PV02** | `--profile` with an unrecognised value exits **2** in all three scripts, with a usage message naming the closed set; `--profile` with no value exits 2; and the closed set appears in each script's header block | D1 properties 2, 4 |
| **PV03** | `--profile graph` and an explicit `--profile kb-summary` each print a line naming the profile in force; with the flag **absent**, no such line is printed and PV01's byte-identity holds. A copy of the script predating the flag therefore fails this assertion instead of silently ignoring the argument | D1 property 3 |
| **PV04** | over a generated `graph.html` under `--profile graph`, `validate-html-output.sh` reports a pass for each of `H1`, `A1.1`–`A1.6`, `A2.1`–`A2.4`, `A3`, `A4.1`, `A5.1`, skip-link, `<noscript>`, `color-scheme`, `S2`, `NM`, `L1` and `L2` — each named individually, so a check that silently stopped running fails the assertion rather than being absent from it — and the emitted `H1` mode is captured | **AC-9**, D2 |
| **PV05** | under `--profile graph`, `L1`'s and `L2`'s input sets over a generated `graph.html` are **non-empty**, and `L2`'s post-`sort -u` set equals exactly the footer's `./relationships.md` and `./external-sources.md` plus `<noscript>`'s `./INDEX.md`; and the same fixture with one companion file removed **fails** `L2` and names the missing target | D2 |
| **PV06** | three fixtures each fail `NM` under **both** profiles: a non-`text/markdown` inline `<script>` whose body exceeds 100 000 bytes and contains `mermaid` (`NM.1`), a `mermaid.initialize(` call (`NM.2`), and a `<script src>` whose URL contains `mermaid` (`NM.3`); and a fixture inlining a same-sized bundle **without** the token passes all three | D2, FR-17 |
| **PV07** | `S2`'s verdict over a generated `graph.html` agrees with the network requirement the page's own footer states (**AC-6**); a fixture carrying an external `<script src>` fails `S2` under `--profile graph` unless the emitted prerequisites declare a network requirement, in which case `S2` reports `[N/A]` **with its reason** and the diff against the same fixture's default run is confined to the `S2` line | C1, **AC-6**, D5 proof 5 |
| **PV08** | a fixture with no `href="#…"` and no `./*.md` link is reported `[VACUOUS]` and exits non-zero under `--profile graph`; the **same** fixture under the default profile keeps today's `0/0 … resolve` pass and exit 0 | D2 |
| **PV09** | passing `--kb-dir <dir>` changes **no** verdict — a fixture whose `./x.md` exists in `<dir>` but not beside the artifact still fails `L2` — and both the `--help` output and the header comment state that the flag sets no resolution basis and that relative `.md` links resolve against the artifact's own directory | D2 |
| **PV10** | *(pin)* `test-contrast-check.sh` passes unmodified: no args → exit 2 with "Usage"; a missing file → non-zero; an unresolvable pair skipped rather than failed under the default profile; a dark override that fails while light passes → exit 1; the shipped `kb.html` → exit 0 | D5 proof 3 |
| **PV11** | the **theme divergence** check passes over the shipped `.aid/knowledge/kb.html` and over a generated `graph.html`; **fails** over a fixture whose only dark block declares no custom property, and over one whose dark block re-declares every light token with the light values — on each failure exiting 1, omitting the `All contrast checks passed` line and emitting a `FAIL`-carrying line after the dark theme block (the three details D3 specifies against `grade-summary.sh:363`–`:368`); and reports `[N/A]` — carrying no `FAIL`/`fail` token and leaving the exit status to the contrast pairs alone — over a fixture with **no** dark block at all — the shape the `:root`-only fixtures in `test-contrast-check.sh` already have | D3 |
| **PV12** | over a fixture carrying, in document order, a `color-scheme`-only dark block, a token-declaring dark block, and a third dark block inside `@media print` re-declaring those tokens with the light values — the shape verified in `component-css.css` at `:4`, `:37` and `:588` — the extracted dark map equals the **second** block's tokens | D3 |
| **PV13** | under `--profile graph`, every `--gk-*` token in feature-007 D5c's kind table and every `--gc-*` token in its D5b holder table is present in **both** theme maps, matches `[a-z-]+`, and is checked against each of `--bg` and `--bg-elev` at a 3.0 target; the pair list at `:97`–`:109` is also checked, each pair at its own 4.5; the default profile's pair set and targets are unchanged; **and in the dark run every background value is the one the dark declarations carry** (PV12's rule), so no graph pair can be measured against a light background — the failure mode this parameterisation exists to close | **NFR-1** (SC 1.4.11), D3 |
| **PV14** | a fixture omitting one palette token exits 1 under `--profile graph`, naming the token and the pair; the same fixture under the default profile exits 0 with the `⚠️` line. A fixture declaring a token named by the existing pair list inside either added block exits 1 naming that token | D3 |
| **PV15** | *(pin)* every token the existing pair list names resolves, under **both** profiles, to the value `component-css.css`'s own blocks declare — asserted over a fixture in which an added graph block declares a conflicting value for one of them, so a merge order that let the graph shadow a chrome token fails | D3, D5 |
| **PV16** | under `--profile graph`, the collected visual set over a generated `graph.html` is **non-empty**, contains the legend `.diagram-box` with non-zero width **and** height, contains **no** entry for the `<canvas>`, and carries a reported `T1`, `T2`, `T3` and `T4` result for every collected visual | D4, **AC-9** |
| **PV17** | a `graph.html` fixture with no collectable visual **fails** under `--profile graph`; the same fixture under the default profile exits 0 with today's trivial-pass message | D4 |
| **PV18** | neither profile's source contains a live-surface class exclusion or any per-element `T2` waiver, and a `.diagram-box` fixture whose children overlap beyond `OVERLAP_TOLERANCE` fails `T2` under **both** profiles | D4 |
| **PV19** | with `playwright` unimportable, both profiles print the SKIP with its remediation and exit 0; with the artifact absent, both print the SKIP and exit 0; a fixture with a genuine `T1` violation exits 1 under both. Under `--profile graph` each skip emits a distinguishable marker, so a lane that always skips is distinguishable from one that always passes | **C-5**, D4 |
| **PV20** | *(pin)* the `chromium.launch` argument list reached on the `kb-summary` path is unchanged (`:185`–`:188`), and **no** capture exemption and **no** additional launch flag exists on **either** path until its Stage 1 trigger fires — so an exemption added speculatively fails this assertion. When one fires, it appears only on the graph branch and `kb.html`'s per-visual `T1`–`T4` lines stay byte-identical | C2, C3, D5 proof 5 |

`test-landscape.md` records prompt-driven skill state machines as not machine-tested by design, so no
suite drives a skill end to end; the assertions above cover the deterministic machinery this feature
touches, and the human visual gate carries what a screenshot cannot.

### Open Items

Each names its owner and its **Q26 class** — a **mechanism** item changes a contract, a field, an
interface, an exit code, an emitted value or an acceptance criterion's truth; an **editorial** item is
a real defect collected onto STATE.md's § Editorial queue and fixed in the Q24 item-9 batched pass. An
item that cannot be classified confidently is treated as mechanism. **Features 001–007 are frozen
(Q26 § Freeze)**, so an item against one of them needs an explicit owner decision rather than an
automatic reopen. None blocks this feature's implementation.

1. **The corrected dark extraction and the theme divergence check apply to both profiles — adopted,
   and reversible by one cell.** This is the one place this SPEC changes `/aid-summarize`'s emitted
   output, so the reasoning is exposed rather than buried. Three grounds for applying it to both: the
   defect makes an existing check **assert a falsehood** (values labelled dark that are the light
   values), which is a correctness defect in the check itself rather than a per-artifact strictness;
   a per-profile block-selection rule would make the two artifacts disagree about what "the dark
   theme *is*" inside one file, which is the divergence C-4 exists to prevent, only worse than two
   copies; and feature-007 Open Item 4 routes the defect itself here, not merely the graph's half of
   it. **The consequences, each established rather than labelled:** `test-contrast-check.sh` passes
   unmodified and the shipped `kb.html` still passes and now satisfies divergence — reached by running
   the script over the shipped artifact (which is what showed the dark block re-reporting light
   values), re-running its arithmetic under the corrected rule, and then walking the divergence check
   fixture by fixture against every `test-contrast-check.sh` assertion (D5 proof 3) rather than against
   this SPEC's reasoning — the step that produced the gate, without which that suite's `:root`-only
   fixtures would have broken. **The accepted cost, whole:** `kb.html`'s dark block reports different
   ratios and gains a line; its dark check becomes **capable of failing** where today it cannot; and
   the gate is a real limit — an artifact declaring no dark theme gets `[N/A]`, so this check is not
   what catches a *missing* dark declaration (for the graph, **PV13**'s both-maps requirement is).
   Because both mechanisms sit behind the profile table, scoping them to `graph` is a one-cell edit if
   the owner prefers the narrower reading of §5.6 consequence 1's "unchanged". **Owner: the work
   owner** — it changes what another skill's gate checks. **Q26 class: mechanism.**
2. **The CI visual-fidelity lane has been skipping unconditionally, so `validate-visuals.mjs` runs
   nowhere automated.** Verified: `.github/workflows/test.yml:105` sets
   `SUMMARY=".aid/dashboard/kb.html"` and the step exits 0 with a SKIP when that file is absent
   (`:100`–`:110`). That path does not exist — the summary lives at `.aid/knowledge/kb.html`, and
   `aid-migrate` **relocates** the old path (`tests/canonical/test-aid-migrate.sh:742`, `:781`;
   `test-contrast-check.sh:89`–`:93` documents the same relocation). This is a pre-existing
   `/aid-summarize` defect in a file no feature in this work owns, and it matters here because the
   graph's visual assurance is specified to reuse that toolchain: wiring the graph into that lane
   as-is would inherit a lane that cannot fail. It is also the concrete case behind **PV19**'s
   recorded-skip requirement. **Owner: the work owner** for the existing lane; **feature-013** for
   the graph's own lane, which must not be added until the skip is recorded rather than absorbed.
   **Q26 class: mechanism** — a gate that never runs and one that does are different gates.
3. **Two of this feature's mechanisms are contingent on feature-002 Stage 1, and one on FR-18.** C2
   (capture exemption) and C3 (launch flag) fire on Stage 1's verdict; C1 (`S2` `[N/A]`) fires on the
   packaging decision. All three are specified and none is built speculatively — **PV20** asserts
   their absence until triggered. **Owners: feature-002** for the Stage 1 verdicts and for choosing
   between its D1a option (a) and option (b); **the work owner and feature-012** for the packaging;
   **this feature** for each mechanism once triggered. **Q26 class: mechanism** if any fires.
4. **`validate-visuals.mjs` can misalign its `T4` data with its visual list, and the graph cannot
   trigger it.** The main collection skips a top-level `<svg>` whose bounding rect is zero (`:340`) at
   the initial viewport, while the `T4` pass re-evaluates the same skip at each
   `OVERFLOW_VIEWPORTS` width (`:447`) — so an `<svg>` whose zero-ness is viewport-dependent would
   shift the position-aligned arrays and attribute one visual's overflow result to another. It cannot
   fire under the reference layout: the graph's only authored visual is a `.diagram-box`, and the
   container branch never skips. Reported because it is real and because nothing else in this work
   would find it. **Owner: the work owner** (a pre-existing defect in a shared script; nothing is
   owed to this feature). **Q26 class: mechanism.**
5. **The graph pairs' background set is `{--bg, --bg-elev}`, and a dedicated surface token would
   narrow it.** D3 note 1 gives the reasoning: no frozen SPEC fixes a canvas surface token, so
   checking against both page-surface tokens is stronger than guessing which one applies and cannot
   be satisfied by choosing a convenient background. **Nothing is asked of feature-007** — the design
   works as it stands. Recorded so that, if `graph-css.css` declares one surface token, the pair set
   narrows deliberately rather than by discovery. **Owner: feature-007 — frozen; narrowing would be
   an owner decision, not an automatic reopen.** **Q26 class: mechanism** only if the owner chooses
   to narrow.
6. **`H1`'s strength is an environment property, and the graph's gate must say which mode ran.** With
   neither `tidy` nor `html-validate` reachable, `H1` degrades to four greps and still prints a pass
   (`:167`–`:169`). This feature requires the mode to be emitted and carried into the report
   (**PV04**); what a grade does with a fallback pass is not this feature's to set. **Owner:
   feature-010** (the graph's rubric). **Q26 class: mechanism** — it changes what a rubric row means.

**Discharged here, and recorded so they are not re-routed.** **feature-009 Open Item 4** (the
`--kb-dir` help/code discrepancy — closed by correcting the documentation, D2, with the reasoning
stated and **PV09** pinning the two together). **feature-007 Open Item 4** in both halves — the two
`contrast-check.mjs` parameterisations (named additional selectors, and the graph pairs at 3:1 with
the existing pairs unchanged at 4.5) and the separable vacuous-dark finding against the same checker
(D3, Open Item 1). **feature-002 Open Item 8** in all three parts — its (a) capture exemption and (b)
launch flag are C2 and C3, and its (c) new pairs at 3:1 are D3's pair set. **feature-008 Open Item
4**'s feature-011 half — option (b) is C2.

**Declined here, and recorded so it is not reinstated.** The `T2` live-surface exclusion the
2026-07-28 draft held in reserve: the canvas matches none of the collector's selectors
(`:303`–`:304`, `:328`), so the waiver has no element to apply to, and an unexercised waiver in a
shared script is a permanently open door. **PV18** makes reinstating it a test failure.

### Figures

**No quantity in this SPEC is a measurement.** Every quantity above is one of four things, and each is
identifiable where it appears. A **value read from a cited artifact on disk**, at the path named beside
it — and, where that artifact has a rendered twin, at the `canonical/` original rather than the render:
every line number, `NM.1`'s byte threshold, `T1`'s default font size, the `4.5` of the
existing pair list, the exit codes, and the `0/0` shape `L1` and `L2` print — that last one quoted from
the script's own output rather than computed. A **target set by a cited external standard**: the `3:1`
of WCAG 2.2 SC 1.4.11, reached through feature-007 D5a and feature-002 D8, which fetched and cited it.
A **set cited rather than counted**: feature-007 D5b's and D5c's token tables, the existing pair list
through its line range, `L2`'s target set through the page elements that emit it, and both
`test-guardrails-d012.sh`'s pins and this feature's own through their ids. And **an enumeration made on
the spot and reproducible from the cited source** — feature-006's class, adopted here — covering every
remaining count: the three scripts, `NM`'s three sub-checks, `H1`'s four fallback greps, the two added
selectors, the two background tokens, and D3's three mechanisms and three `grade-summary.sh`
details, each of which is named individually where it is counted. Two quantities are
deliberately cited **by the constant that holds them** rather than by value — `T2`'s overlap tolerance
and `T4`'s viewport widths — because those are the things a future edit would change.

**No node count, row count, bench size, frame rate, settle time, payload figure or contrast ratio is
asserted anywhere in this document**, and nothing here needs one. The verdicts this feature reached by
running a script over a committed artifact — that the dark theme block currently re-reports the light
values, and that the corrected extraction leaves the shipped summary passing — are stated as
**verdicts with their reproduction named** and are converted into assertions (**PV01**, **PV11**)
rather than recorded as figures, because a figure in a SPEC is a claim that goes stale silently while
an assertion fails loudly. The withdrawn delivery-001 bench and the withdrawn requirements node total
are not reproduced here even to retire them, which is how the last one kept reappearing; and
**AC-6a**, the only criterion in this work that is inherently a measurement, is feature-008's and
feature-002's — this SPEC satisfies no part of it and asserts nothing about it.
