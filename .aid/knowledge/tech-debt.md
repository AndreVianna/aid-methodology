---
kb-category: primary
source: hand-authored
objective: Severity-classified open technical and methodology debt in AID — dead code, lockstep-config hazards, blocked release channels, stale docs, large files, and security observations — each with location, risk, and resolution note.
summary: Read this before starting work in any area; declared debt items and the non-obvious gotchas (lockstep manifests, master-only gates, render-drift ordering, HOME-pinning) may change your approach or scope.
sources:
  - install.sh
  - dashboard/MANIFEST
  - tests/canonical/test-dashboard-manifest.sh
  - lib/aid-install-core.sh
  - docs/repository-structure.md
  - canonical/EMISSION-MANIFEST.md
  - canonical/aid/scripts/execute/writeback-state.sh
  - .claude/skills/generate-profile/SKILL.md
  - .github/workflows/release.yml
  - release.sh
  - .github/workflows/test.yml
  - .aid/generated/project-index.md
tags: [C7, tech-debt, risk, security, gotchas, remediation]
see_also: [test-landscape.md, infrastructure.md, quality-gates.md, architecture.md]
owner: architect
audience: [developer, architect, pm]
intent: |
  Severity-tagged open technical and methodology debt with locations, risk, and
  remediation. Includes security observations (as debt items) and the non-obvious
  gotchas a change will trip. Diagnosis, not a sprint plan.
contracts: []
changelog:
  - 2026-07-30: work-001 final gate -- RESOLVED and removed W1-16 (task-058, owner chose fix-over-disclose). Rule 7 now requires a state to be the TARGET of a loop/return phrase, tested over the joined logical block rather than the physical line (three genuine loop-backs wrap the verb onto the previous line, and the shared engine wraps the other way), plus a filename guard for the state-name/artifact-name collision. Measured: cross-state loop-back edges 26 -> 20, 74 self-loops untouched, exactly 8 files changed, generator still idempotent. Re-verified by re-running the AC-7 spot-check on the corrected chart.
  - 2026-07-30: work-001 final gate -- added W1-17 (the AC-1 drift-guard test writes a scratch page into the tracked content collection, so an interrupted run breaks the next build; raised at delivery-002's gate and left Pending there).
  - 2026-07-30: work-001 final gate -- added W1-16: the flow extractor's rule 7 turns prose cross-references into loop-back arrows on published charts. Found by performing AC-7, the comprehension spot-check delivery-004 never recorded -- the unfamiliar reader reported 3 loop-backs on the first chart it was shown, where the source has 1. Extent then measured exactly by a gate reviewer: 7 fabricated arrows on 4 charts, and a second trigger the first analysis missed (a state name colliding with its artifact filename, which makes aid-design 3-drawn/0-real). Medium/P2, escalated to the owner rather than fixed -- tightening rule 7 changes corpus-wide generated output that two deliveries assert byte-unchanged.
  - 2026-07-30: work-001 final gate -- added W1-13/W1-14 (node-panel accessibility: no role or accessible name; aria-controls references a lazily-created panel that does not exist before first activation) and W1-15 (the screen-reader announcement check has never been run against a real screen reader). All three surfaced by PERFORMING delivery-005's four manual browser checks, which had been made non-blocking and then never performed.
  - 2026-07-30: work-001 final gate -- RESOLVED and removed W1-4 (the `docs.yml` CI-lane row taught the wrong CI model). Corrected in SIX places across three docs, after a gate reviewer showed the first pass had closed only half the class: the trigger rows in `test-landscape.md`, `infrastructure.md` and `integration-map.md` (all three omitted the `canonical/**` filter and the `pull_request`-to-master trigger; two carried a `release: published` trigger that does not exist), AND three 'heavy gates are master-only' summaries that assert the same wrong model in prose -- `tech-debt.md` Gotchas, `integration-map.md`'s CONFIRMED note, and `test-landscape.md`'s own section lead-in. The first pass also introduced a false claim (that the site build catches canonical->profiles render drift; that is `test.yml`'s `render-drift` job, and `site/` never reads `profiles/`) and left the corrected text pointing at an uncorrected instance. IDs are not renumbered, so W1-4 is now a deliberate gap.
  - 2026-07-30: work-001 delivery-006 gate -- added W1-1..W1-12, the work-001 known-issues that would not survive the work folder being pruned, with their own table header; corrected an initial mis-classification that restated three CLOSED issues as open; corrected a stale present-tense corpus count. Open debt is no longer L4 alone.
  - 2026-06-25: Initial debt audit (aid-discover quality deep-dive)
---

# Tech Debt

This document is a diagnosis, not a sprint plan. It records what currently exists so agents
do not create more of it. **Only currently-open debt is listed**; resolved items are removed
entirely (git history is the audit trail).

A note on overall health: AID's source is unusually clean for its size. A scan for genuine
`TODO`/`FIXME`/`XXX`/`HACK` markers across `canonical/`, `lib/`, `bin/`, `dashboard/`,
`install.sh`, `install.ps1`, and `release.sh` returns **zero real markers** — the only hits
are `mktemp ... XXXXXX` templates (CONFIRMED via grep). The debt below is therefore
structural and methodological, not littered code.

## Contents

- [Debt Inventory](#debt-inventory)
- [Detailed Debt Items](#detailed-debt-items)
- [Complexity Hotspots](#complexity-hotspots)
- [Missing Test Coverage](#missing-test-coverage)
- [Outdated Dependencies](#outdated-dependencies)
- [Duplication](#duplication)
- [Dead Code](#dead-code)
- [Security Observations](#security-observations)
- [Gotchas](#gotchas)
- [Change Log](#change-log)

---

## Debt Inventory

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| **L4** | Test-effectiveness gap | No systematic measure of test-suite **effectiveness**. Line-coverage `%` is (still) rejected as the wrong tool for a mostly-non-instrumentable product (see `decisions.md` D26), but the AID-appropriate measures — mutation testing, invariant-anchoring, behavioral-surface coverage, escaped-defect tracking (dogfooding is already in place) — are not yet implemented as a program. Nothing today tells us whether the ~133 suites actually *bite*. | whole test suite / CI | **High** | M (phased) | **P1 — next release** |

**Risk definitions:** High = active risk to reliability/security/maintainability of core
flows; Medium = growing cost, becomes high if unaddressed in 1-2 cycles; Low = known, not
urgent.

---

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| **W1-1** | Third-party integration bug | `astro-mermaid` never forwards a **top-level** `themeVariables` to `mermaid.initialize` — it destructures only `{theme, autoTheme, mermaidConfig, iconPacks, enableLog}` and builds its client config as `{startOnLoad:false, theme, ...mermaidConfig}`, so a palette passed one level too high is silently dropped. **⚠️ DO NOT "fix" this by nesting the palette under `mermaidConfig`.** That forwards it successfully and thereby pins **one** palette across **both** themes `autoTheme` switches between, so the dark colours bleed into light mode — strictly worse than the inert palette. AID's resolution was to **delete** `themeVariables` and move per-theme colour to CSS, where `[data-theme]` can select (`site/src/styles/casulo.css`, mermaid block); `mermaidConfig` now carries layout only, which is theme-independent and safe to fix there. So the site is correct today and this row records only the **upstream** gap, in case a future need for config-level theming arises. Independently mitigated: generated charts emit a self-contained `classDef` block, so they are legible either way. | `site/astro.config.mjs`:35-42 (the warning, inline at the site) vs `astro-mermaid-integration.js`:229-235 | Low | S | P3 |
| **W1-2** | Stale KB facts | `module-map.md` § Skill Structural Shapes carries per-shape population figures that no measurement supports ("roughly 94 of the 111"). Two independent scans agreed on the inline-state population but differed on the doorway/residual split. The live figures belong in the generator's `shapeCounts` manifest entry, not in prose — the row should be regenerated from it or lose its numbers. | `.aid/knowledge/module-map.md` § Skill Structural Shapes | Low | S | P3 |
| **W1-3** | Graceful-degradation gap | Client-side mermaid rendering means a reader without JavaScript sees raw `flowchart TB …` source inside an animated placeholder. Accepted at design time (the below-chart ordered list is static markdown and carries the same information), but it now affects all 111 skill detail pages rather than 4. | `astro-mermaid-integration.js`:64, 316-318 | Low | M | P3 |
| **W1-5** | Extractor gap | The `X (optional) then Y` advance form is not split by the flow extractor, so a state carrying it renders one edge where two are meant. | `site/scripts/lib/flow-graph/advance.mjs` | Low | S | P3 |
| **W1-6** | Stale curated roster | `SKILL_GROUPS` files `aid-triage` under *Definition* where FR-5 puts it in *Support*. No longer rendered anywhere, but still read by the corpus drift guard, by `skill-counts.mjs`'s `curatedOnly`, and by the derived grouping-divergence note on `/skills/` — so correcting it is a real change with real consequences, deliberately not folded into delivery-006. | `site/scripts/skills/curated-roster.mjs` | Low | S | P3 |
| **W1-7** | Misleading signal | `data-processed` on a mermaid container means "render attempted", not "SVG present" — an error `<div>` also carries it. Consumers must check for an actual `<svg>`. | `astro-mermaid-integration.js` | Low | S | P3 |
| **W1-8** | Missing re-entrancy guard | `initMermaid()` has no re-entrancy guard, so rapid theme toggling can interleave two render passes over the same container. | `astro-mermaid-integration.js` | Low | S | P3 |
| **W1-9** | Contradictory templates | The two task templates disagree with each other, and one claims a conformance property it does not enforce. | `canonical/aid/templates/delivery-plans/` | Low | S | P3 |
| **W1-10** | Environment trap (Windows) | Worktrees for this repo must be created with **Windows git**, never WSL git — a WSL-created worktree produces paths the Windows toolchain cannot resolve, and the failure is confusing rather than immediate. | process / dev environment | **Medium** | — (documented) | **P2** |
| **W1-11** | Cross-work collision | work-004 shrinks the skill corpus 111 → 74 and also renames skills. Every count guarded by `tests/canonical/check-skill-counts.mjs` derives automatically, but hand-written *names* and any prose enumerating skills will need reconciliation when that work lands. | repo-wide | **Medium** | M | **P2** |
| **W1-12** | Intermittent rendering defect | ELK layout is intermittently not applied — diagrams fall back to dagre routing, producing the curved, overlapping edges the owner explicitly rejected at the delivery-003 UI checkpoint. `layout: 'elk'` is present and the loader registers; two hypotheses remain live and untested. **Owner-deferred**, shipped open and disclosed. | `site/astro.config.mjs`:47 + `@mermaid-js/layout-elk` | **Medium** | M | **P2** |
| **W1-13** | Accessibility gap | The node-detail panel is a `div[tabindex="-1"]` with **no `role` and no accessible name** — the accessibility tree shows it as `generic`. Activation moves focus into it, so what a screen reader announces on arrival is not deterministic across NVDA / JAWS / VoiceOver. It does carry an `<h3>` naming the step and a labelled close button, so the content is reachable; the framing is what is missing. Fix is `role="region"` (or `dialog`) plus `aria-labelledby` pointing at the existing `<h3>`. | `site/public/skill-node-panel.mjs` / `site/src/lib/skill-node-panel.ts` | Low | S | P3 |
| **W1-14** | Invalid ARIA | Every decorated node carries `aria-controls="aid-node-panel"` from page load, but the panel is created **lazily on first activation** — so before any node is activated the attribute references an element that is not in the DOM. Confirmed on a fresh load: `document.getElementById('aid-node-panel')` is null while 5 nodes already advertise it. `aria-controls` is specified to reference an existing element. | `site/public/skill-node-panel.mjs` | Low | S | P3 |
| **W1-15** | Unperformed verification | The **screen-reader announcement** check has never been run against a real screen reader. The work-level final gate verified the mechanism (accessibility tree + focus movement) in Chromium, which is not the same thing as the utterance. Needs one NVDA or VoiceOver pass over a skill detail page's chart. Tracked because the check is named in `REQUIREMENTS.md` and in feature-006's blocking default, and a mechanism inspection was substituted for it. | process / manual QA | Low | S | P3 |
| **W1-17** | Self-inflicted build break | The AC-1 drift-guard test writes a synthetic orphan page `__test-orphan-skill__.md` **directly into the tracked content collection** (`site/src/content/docs/skills/`) and removes it only in cleanup. An interrupted or killed `npm test` leaves a scratch page in a tracked directory, and the next `npm run build` then fails on the very drift guard the test exercises — a build break caused by the test suite. Every run also momentarily injects a page into the collection a dev server is watching. `discoverSkills()` already accepts a `skillsDir` override and `mkdtempSync` is already imported in the file, so a temp-tree variant needs no new machinery. Raised at delivery-002's gate, left `Pending` there, and carried here at the final gate because it is the one of that gate's unclosed rows whose consequences outlive the work folder. | `site/scripts/__tests__/gen-skills.test.mjs`:539-545, 572-573 | Low | S | P3 |

### work-001 (Skill Explorer) — issues that outlive the work folder

work-001 registered 22 known issues over its lifetime. **Twelve are closed** — KI-003, 005, 006,
009, 012, 013, 016, 018, 020 and 021 during the work, then KI-001 and KI-007 at the work-level
final gate. Their closures were recorded inconsistently — some on a `Status:` line, one in a
heading, one in a body bullet, one on a `Type:` line — which is why classifying them by the
presence of a `Status:` line mis-read four of them. That is a lesson about the KI format, not a
pointer: this section deliberately carries **no path** to the work's issue file, because
`pipeline-contracts.md § Invariants` forbids the KB from citing a work folder as a source, and this
is the section whose entire purpose is to outlive that folder being pruned. Everything a later
reader needs is restated in the rows above.

The still-open ones are listed above as `W1-1`..`W1-3`, `W1-5`..`W1-15` and `W1-17` — **fifteen items** —
because of the project's own rule that **work folders are transient**: `.aid/works/work-NNN-*/`
may be pruned once a work ships, and no permanent artifact may depend on it. Left only there, they
would have been deleted along with the folder — including a Medium-priority Windows worktree trap
that costs an afternoon (`W1-10`) and the one item the owner explicitly deferred rather than
resolved (`W1-12`).

`W1-16` is likewise absent by resolution: it recorded the flow extractor turning prose
cross-references into loop-back arrows on published charts. Asked whether to ship it disclosed or
fix it, the owner chose to fix it, and **task-058** did — 7 wrong edge-attributions removed from 4
charts, 1 genuine edge recovered with correct provenance, verified by re-running the same AC-7
comprehension spot-check that found it (a clean-context reader now reports exactly the one
loop-back the source expresses, where it previously reported three).

`W1-4` is absent by resolution, not by oversight: it recorded the `docs.yml` CI-lane row teaching
the wrong CI model, and the work-level final gate fixed it — in **six** places, not the one the
finding cited. Three were table/prose rows describing the workflow's triggers; three more were
"heavy gates are master-only" summaries that the first pass missed and a reviewer caught,
including one that the corrected text itself pointed the reader at.
Per this KB's convention a resolved item is **deleted** rather than marked done — the closure
record lives in the `changelog:` frontmatter and in git. IDs are not renumbered, so the gap at
`W1-4` is expected and any outside reference to it still resolves through history.

`W1-13`..`W1-17` were **not** in the work's own issue ledger. They were found at the work-level final gate by
performing delivery-005's four manual browser checks, which the owner made non-blocking and which
were then never performed; by performing **AC-7**, the comprehension spot-check delivery-004 owed
and never recorded; and by transcribing delivery-002's gate ledger, which had been left an unfilled
template placeholder. Breakdown: `W1-13`/`W1-14` are real accessibility defects in shipped code;
`W1-15` is the screen-reader pass still owed, recorded so that substituting a mechanism inspection
for it cannot later read as the check having been done; `W1-16` was a Medium defect in published chart output that an unfamiliar
reader spotted in the first chart shown to it, **fixed by task-058 and removed from this table**; `W1-17` is a
build-breaking test hazard that had been raised at delivery-002's gate and left `Pending` there.

**Every one of the five came out of a check that had been deferred, waived as non-blocking, or
left unrecorded.** None came from the code review that ran alongside them. That is the argument
for performing deferred checks before shipping rather than after — and, since four of the five were
found at the *final* gate rather than at the delivery that owed them, for not accepting "recorded
later" as equivalent to recorded.

> **Corrected 2026-07-30 at gate cycle 3.** The first version of this section said seven
> closed / fifteen open and restated CLOSED issues as open (three at first, then a
> fourth -- KI-018, RESOLVED 2026-07-28 with a shipped fix -- which survived the first
> correction because I recounted the split without re-checking each row against it) — including one whose text
> ("`CHARTABLE_SHAPES` was never widened") is false on disk: `gen-skills.mjs` uses
> `new Set(SHAPE_ORDER)` and all 111 sidecars emit. The classification had been read off the
> presence of a `Status:` line. Closures are recorded four different ways across the file --
> a `Status:` line, a heading (KI-020), a body bullet (KI-018) and a `Type:` line (KI-021) --
> so that heuristic mis-read four entries, and correcting the totals without re-checking each
> row against the source let one of them survive a second pass.

They are restated here in full rather than cross-referenced, for the same reason: a pointer
into a folder that is allowed to disappear is not a record. The work folder keeps the fuller
investigation notes for as long as it exists; this inventory is what survives it.

## Detailed Debt Items

### [HIGH] L4 -- No measure of test-suite effectiveness

**Type:** Test-effectiveness gap / methodology

**Description:** AID has ~133 canonical suites but **no signal for whether they are
effective** — i.e. whether they would actually fail if the code broke. Line-coverage `%`
is *not* the answer and remains rejected (D26): the shippable product is ~1,800
Markdown/prompt files + ~327 shell/PowerShell files + a byte-identical render, so a
coverage number would instrument <5% of it and mislead. But rejecting line-coverage is not
the same as measuring effectiveness, and today we measure it for the deterministic
machinery **not at all**. The `io_bounds.py` incident is the proof: five install manifests
plus two installer-test lists all asserted each other and "passed" while every one of them
was missing a shipped, security-relevant file. The tests ran; they did not bite.

**Why now (promoted Low -> High, 2026-07-10):** owner and architect agreed this is "big and
important" — the missing effectiveness signal is an active reliability/security risk (it
already let a DoS-guard omission reach a release-candidate), not a cosmetic gap. Targeted
for the **next release**.

**Scope boundary (important):** this is about the **deterministic, machine-executed**
surface — installers (`install.sh`/`install.ps1`/`lib`), the dashboard reader (Python +
`.mjs`), the render/generator pipeline, the manifests, and the canonical helper scripts.
The ~113 prompt-driven skills are **out of scope** for these techniques (there is no
deterministic pass/fail to measure) — they are covered by **dogfooding + review**, which is
already in place. Effectiveness measurement therefore scales with the (bounded, slow-growing)
machinery, NOT with the number of skills.

**The five measures (suggestions):**

1. **Mutation testing** — the direct measure: inject a deliberate fault, confirm a suite
   goes red. A *surviving* mutant is a blind spot. Language-agnostic (works on shell). It is
   a **thermometer, not a proof** — never "complete," but it tells you whether the suite bites.
2. **Invariant-anchoring** — a review rule: every assertion must compare a derived artifact
   to the **source of truth** (canonical source, actual filesystem, spec), never to a sibling
   copy that can drift in lockstep. (`list == list` is what let `io_bounds` through;
   `MANIFEST == actual tree` is what catches it.)
3. **Behavioral-surface coverage** — the AID analogue of a coverage `%`: enumerate the
   observable surface (each subcommand x platform x exit code x channel) in a table and tick
   off which cells have a gating test ID. The gaps are the "uncovered" cells.
4. **Escaped-defect tracking** — a ledger of every bug that reached master/release that a
   test should have caught; each becomes a regression test **and** a named fault class. This
   is what makes the mutation set converge on *this* codebase's real fault space over time.
5. **Dogfooding** — the only effectiveness signal for the prompt/skill layer. **Already in
   place** (listed for completeness).

**Implementation proposal (phased, next release):**

- **Mutation testing — two tiers, cost-bounded so it does not explode:**
  - *Tier 1 (per-PR, curated, fast):* ~15-25 hand-authored "named fault class" mutations for
    the load-bearing invariants (delete a `MANIFEST` line; flip an installer exit code
    2->0; corrupt a checksum; off-by-one a bound). Each runs **only its relevant suite** (via
    a test-impact map), not all ~133. Shell lives here (no good off-the-shelf shell mutator).
    Not meant to be complete — it *guards the classes that have burned us*.
  - *Tier 2 (nightly / pre-release, automated, scoped):* a real mutator on the instrumentable
    minority — `mutmut`/`cosmic-ray` (Python reader), `stryker` (`.mjs`/site) — to probe the
    long tail. Kept from exploding by: scope to the deterministic modules only; on PRs mutate
    only the changed diff (incremental); random-sample under a time budget (e.g. 30 min,
    rotating); run only impacted suites per mutant; keep the full run off the PR path.
  - *Feedback loop:* recurring Tier-2 survivors get **promoted** into Tier-1; every escaped
    defect (below) becomes a new Tier-1 mutation. The curated set grows to match reality — the
    empirical answer to "are N mutations enough?" (you never guarantee it up front).
- **Escaped-defect ledger:** `tests/ESCAPES.md` (or a `test-landscape.md` section) — one row
  per shipped/RC bug a test should have caught: date, symptom, blind class, regression test,
  generalized guard. Rule: fixing an escape requires both a regression test and a ledger row.
  Seed it with `io_bounds.py` and the earlier `home.html` omission (same "manifest-drift" class,
  now guarded by `test-dashboard-manifest.sh`).
- **Behavioral-surface matrix:** a table in `test-landscape.md` mapping each behavior -> the
  guarding test ID, plus a small checker that confirms every named ID exists. Output: "N/M
  behaviors guarded; here are the gaps."
- **Invariant-anchoring rule:** one line in the test-authoring guidance + the `aid-reviewer`
  rubric ("anchor to ground truth, not a sibling copy"); optionally a cheap lint flagging a
  test that diffs two generated/vendored copies against each other.

**Acceptance for the release:** at minimum Tier-1 mutation testing wired into
`run-all.sh`/CI with a killed/injected score, the escaped-defect ledger established and
seeded, and the invariant-anchoring rule in the reviewer rubric. Tier-2 automation and the
behavioral matrix can follow if time-boxed out, but the ledger + Tier-1 + review rule are the
must-haves (they close the exact gap that let `io_bounds` through).

---

## Complexity Hotspots

Large files concentrate complexity (line counts drift — measure on demand). CONFIRMED via
`.aid/generated/project-index.md` "Top 20 Largest Source Files".

| File | Why complex | Notes |
|------|-------------|-------|
| `dashboard/server/reader.mjs` (~4012) | Full KB/state parser re-implemented in Node | Triplicated (see Duplication) |
| `tests/canonical/test-aid-cli-parity.sh` (~3198) | Exhaustive bash↔PS behavior matrix | Large but flat assertions |
| `tests/windows/Test-AidInstaller.ps1` (~2406) | Whole installer surface in one PS script | Windows-CI only |
| `dashboard/reader/parsers.py` (~2232) | Python KB/state parser | Triplicated |
| `lib/aid-install-core.sh` (~2160) | The install/update/remove engine | Triplicated; most load-bearing shell file |
| `install.sh` (~1043) | Bootstrap + provisioning | Bootstrap/convenience/uninstall-cli modes + dashboard provisioning |
| `.claude/skills/.../render.py` (~1019) | The profile renderer | Has self-tests |

---

## Missing Test Coverage

| Module / Function | Coverage | Type missing | Risk |
|------------------|----------|--------------|------|
| Prompt-driven skill state machines | none (by design) | integration | Accepted — needs AI host + human; covered by dogfooding + review |
| Astro site components | partial | unit | Build is the main gate; component logic lightly tested |
| Windows installer path | strong but Windows-CI-only | — | A green local `run-all.sh` does not exercise it (see Gotchas: master-only heavy gates) |

---

## Outdated Dependencies

No CVE-flagged or end-of-life dependency was identified. AID's runtime payload is shell +
markdown with near-zero third-party runtime dependencies (the npm package advertises zero
runtime deps). Heavier dependency trees are confined to the **separate** `site/` Astro build
(`site/package-lock.json`) and the summarize Playwright tooling
(`.claude/aid/scripts/summarize/package.json`); `.github/dependabot.yml` is configured to
track updates. No action item beyond letting Dependabot run. CONFIRMED via project-index
(manifests list) + `dependabot.yml` presence.

---

## Duplication

> Intentional duplication — do not "deduplicate"; it is the source-of-truth + vendored-copy
> design. Listed so a change knows every copy to update.

| Area | Copies | Risk if not kept in sync |
|------|--------|--------------------------|
| `reader.mjs` | `dashboard/`, `packages/npm/dashboard/`, `packages/pypi/aid_installer/_vendor/dashboard/` | Dashboard behaves differently per install channel |
| `parsers.py` | same three locations | Same |
| `aid-install-core.sh` | `lib/`, `packages/npm/lib/`, `packages/pypi/aid_installer/_vendor/lib/` | Install logic diverges per channel |
| `canonical/` toolkit | rendered into 5 `profiles/` + `.claude/` | Caught by the render-drift gate (CI) |

The `canonical/ → profiles/` duplication is machine-guarded (render-drift). The
`dashboard`/`lib` vendored copies are guarded by the channel install suites; the vendoring is
done at build/pack time by `vendor.js` / `vendor.py`, so editing the source-of-truth copy and
re-vendoring is the correct workflow. The **dashboard file *set*** (which files make up the
server+reader unit) is not duplicated: all five install/vendor paths derive it from the
single-source `dashboard/MANIFEST`, guarded by `tests/canonical/test-dashboard-manifest.sh`.

---

## Dead Code

No dead code is currently identified. A scan of the shipped scripts finds no unreachable
branches. (The previously-listed `OVERALL_BLOCKED` / `exit 5` / `.aid-new` protect-on-diff
branch was removed from `install.sh` + `install.ps1`; git history is the audit trail.)

---

## Security Observations

Security findings are recorded here as debt items (there is no separate security doc).
Overall posture is solid for a CLI installer; the main inherent risk is the bootstrap trust
model.

| Observation | Severity | Detail |
|---|---|---|
| `curl\|bash` / `irm\|iex` bootstrap | Medium (inherent) | Users pipe a remote script to a shell. Mitigated: the bootstrap fetches the CLI bundle + libs from a **pinned release tag** and verifies them against `SHA256SUMS` before sourcing (CONFIRMED in `release.sh` Step 6 comment + `install.sh` lib-fetch). The trust root is the GitHub Release. |
| No detached signature on GitHub tarballs | Low (accepted) | `release.sh --sign` is a stub (a deferred feature, not wired into `release.yml`). Accepted as not-needed: npm publishes with `--provenance` and PyPI with PEP 740 sigstore attestations (the channels most users install from), and GitHub tarballs are checksum-verified against `SHA256SUMS`. A detached GPG signature would add key-management burden for marginal gain; revisit only if the threat model changes. |
| Publish auth uses OIDC Trusted Publishing | Positive | npm publishes with `--provenance`; PyPI publishes with PEP 740 attestations via `pypa/gh-action-pypi-publish` — both token-less via OIDC. CONFIRMED in `release.yml`. |
| Least-privilege CI permissions | Positive | `test.yml` / `installer-tests.yml` / `coverage-parity.yml` use `permissions: contents: read`; `release.yml` grants only `contents: write` + `id-token: write`; `docs.yml` only `pages: write` + `id-token: write`. CONFIRMED. |
| Optional `NPM_TOKEN` classic automation token | Low | If OIDC is not used for npm, a classic `NPM_TOKEN` secret is the fallback (`release.yml` header). Prefer Trusted Publishing to avoid storing a long-lived token. |
| No secrets committed | Positive | No credentials in tracked files; auth is via CI secrets/OIDC only. |
| Dashboard binds localhost by default | Positive | The dashboard server binds `127.0.0.1`; `--remote` is a clear-fail stub (exit 10), so it cannot accidentally expose state on a network. CONFIRMED in `installer-tests.yml` dashboard smoke. |

---

## Gotchas

> Non-obvious traps a contributor cannot infer from the code alone. State the trap, then the
> safe way through it.

- **Master-only heavy gates — with one exception that matters.** The full canonical suite
  (`test.yml`'s `canonical-tests`) runs on `master` and release tags only, so a branch with **no
  open PR to master** can red-master in ways it never saw. Run `bash tests/run-all.sh`
  (HOME-pinned) before merge.
  **`docs.yml` is NOT master-only.** It triggers on `push` *and* `pull_request` to `master`, both
  path-filtered to `site/**`, `docs/**`, `canonical/**`, `VERSION` or the workflow itself, and its
  `build` job runs **`npm test` (the site vitest suite) as well as the Astro build**. Only the
  `deploy` job is master-only. It has **no `release:`/tag trigger at all** — the `github-pages`
  environment rejects a non-master ref, so a post-release refresh is a manual
  `workflow_dispatch`. Two consequences: a **`canonical/`-only** commit still rebuilds the site,
  and a PR touching those paths is genuinely gated on the site suite.
- **HOME-pinning before any migration-scan test:** the migration scan defaults its root to
  `$HOME`; a test firing it must `export HOME=<throwaway>`, not just `AID_HOME`, or it
  migrates the developer's real repos. CI also checks the repo out (with its own `.aid/`)
  under `$HOME`, so isolation canaries must snapshot `REAL_HOME` before/after.
- **Render-drift needs the FULL generator:** after editing `canonical/`, run
  `python .claude/skills/generate-profile/scripts/run_generator.py` (the full generator), not
  a per-script renderer — otherwise the render-drift gate fails on stale `profiles/`
  emission manifests.
- **One dashboard manifest, five consumers:** the dashboard server+reader file set lives in
  `dashboard/MANIFEST` (one path per line). `install.sh`, `install.ps1`, `vendor.js`,
  `vendor.py`, and `release.sh`'s CLI bundle all DERIVE their file set from it — never re-list
  the files inline. Add/remove a dashboard source file by editing `dashboard/MANIFEST` only;
  `tests/canonical/test-dashboard-manifest.sh` fails CI if the manifest drifts from the curated
  `dashboard/` tree or if a consumer stops referencing it (H1 guard).
- **Four version carriers must agree:** `VERSION`, `packages/npm/package.json`,
  `packages/pypi/pyproject.toml`, and the git tag must all match, or
  `check-version-sync.sh` fails the release `gate`. Bump them together.
- **Edit `canonical/`, never `profiles/`:** `profiles/` is generated build output; hand-edits
  are wiped on the next render and fail render-drift.
- **ASCII-only shipped PowerShell:** Windows decodes no-BOM UTF-8 in the ANSI codepage and
  mis-parses non-ASCII; `test-ascii-only.sh` + `test-ps51-compat.sh` gate this. Keep shipped
  `.ps1`/`.psm1` ASCII and 5.1-compatible (no 3-arg `Join-Path`, no `-Encoding utf8NoBOM`,
  no `$IsWindows`, force TLS 1.2).
- **Web-output reviews require Playwright:** reviewing `kb.html` or the site by reading
  HTML/CSS is not a valid review — render and visually validate (the `visual-fidelity` gate).
- **`master` is branch-protected:** the bot identity cannot push to `master`; always open a
  PR (never direct-push/force-push master).

---

## Change Log

Resolved items are removed from this document as they close (see the note at the top of the
file); the full history — the initial audit and every closure — lives in git
(`git log --follow .aid/knowledge/tech-debt.md`). Only currently-open debt is described above.

| Rev | Date | Source | Open debt |
|-----|------|--------|-----------|
| 2.4 | 2026-07-10 | tech-debt-followup | **L4** — no measure of test-suite effectiveness; opened High / P1 as a next-release program (see Detailed Debt Items). Sole open item. |
| 2.5 | 2026-07-24 | work-024 test-suite-improvement KB refresh | Corrected **L4**'s stale suite count ~118 → ~133 (live total, matching `test-landscape.md`); no residual-gap row added — the ≤3min/~90s outcome is measured on the post-push CI run, and a later KB-DELTA adds an `L5` row only if the ~90s goal is missed. **L4** remains the sole open item. |
| 2.6 | 2026-07-30 | work-001 delivery-006 gate | **L4** plus **W1-1..W1-12** — the work-001 known-issues migrated out of the transient work folder (two Medium traps among them: a KB row teaching the wrong CI model, and a Windows worktree trap), so L4 is no longer the sole open item |
