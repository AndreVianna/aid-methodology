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
  - 2026-08-05: work-005 Detail phase -- added W5-5 and W5-6, both found by USING the pipeline rather than reading it. W5-5 is the sharper one -- every pipeline-phase state write in the methodology fails silently, because `writeback-state.sh` defaults to a placeholder `.aid/works/work/STATE.md` and all 14 `--pipeline` call sites across 7 skills omit the `AID_STATE_FILE` export it needs, while the snippet is documented as a silent no-output write so the exit 1 never surfaces. Observed consequence, and how it was found -- work-005's own STATE.md sat with its phase field still reading Specify for days after Specify closed and had to be hand-corrected, which means the tracking discipline CLAUDE.md calls IMPERATIVE is only ever right when a human notices it is wrong. W5-6 collects four verified task-template inconsistencies, the worst being a literal `[CRITICAL] {description}` example row inside an AUTHORED section that reads as a real recorded finding if seeded verbatim. Later the same day, running /aid-execute found a second W5-5 instance on the task-state write path, which needs AID_WORK_DIR rather than AID_STATE_FILE and is undocumented at all of its own MANDATORY call sites, so the 14-site --pipeline fix does not close the item. Executing wave 1 then opened W5-7 and W5-8, both found by an executor doing the work rather than by any gate; W5-8 is the serious one, a deliverable feature-004's own SPEC says feature-004 implements, absent on disk, unassigned by all 29 tasks, and reading as closed because its acceptance test drives a stub resolver instead of the shipped one. W5-8 was then RESOLVED the same day by work-005 task-030, which shipped the flag and rewired the acceptance assertion through the real resolver, so its row is deleted here rather than annotated -- a resolved item stays only in this changelog and in git. W5-7 remains open. Wave 3 then opened W5-10 and W5-11. W5-10 is the FIFTH ownerless obligation in this one work and the reason the pattern is now recorded as debt in its own right -- every one of the five was found by an executor doing the work, none by a reviewer reading it. W5-11 is a SPEC contradicting the very line it cites, caught only because an executor had to implement the clause and found it unimplementable as written. Wave 2 then opened W5-9, found by task-016 while writing feature-009's table suite -- 11 of its own DOM-grounded acceptance assertions skip in CI as well as locally, because jsdom is a site-only dependency the canonical suites cannot resolve, so a third of the feature's assertions sit inert behind a green run.
  - 2026-08-05: work-005 test-strategy update (second pass) -- added W5-4, the mutation-harness cost defect. Each mutant re-runs the WHOLE suite (`bash "$SELF"`), making the matrix an ~8x multiplier -- 40 subject scans and ~584s to test seven one-line defects, and the reason two builders spent the bulk of a 2.5-hour run in mutation loops. It breaks S1, the rule three rows above it in the same table. Recorded WITH its fix (mutant runs its own assertion group; library-level mutants skip the pipeline entirely; mutants sharing a fixture share a scan) and with an explicit prohibition on resolving it by dropping mutants, since the matrix is the only oracle that caught three suites green against a broken subject. S3 narrowed so a matrix is required only where an assertion can be vacuous.
  - 2026-08-05: work-005 test-strategy update -- added W5-3, found while validating this very update -- 6 of the 21 KB docs have frontmatter that is not valid YAML, every case a colon-plus-space sequence inside the prose of a changelog entry (which is itself a single-key date mapping, so the second colon reads as a second mapping value), and the gate named after frontmatter is structurally blind to it because `lint-frontmatter.sh` validates field presence and list-vs-scalar shape textually while FL19 soft-skips AID's own KB docs. Latent rather than breaking, because no consumer YAML-parses these files. Also added W5-1 (the `# COVERS:` change-set-selection convention is landed in `tests/canonical/select-suites.sh` but rolled out only to work-005's graph suites, so ~135 suites are still always-selected fail-safe and `--glob` is required; carries an explicit warning NOT to invert the fail-safe direction, which would trade wasted time for silently skipped suites) and W5-2 (`scan-source.sh` spends ~8.4s of ~9.8s on a TWO-FILE repo in ~100 process spawns, at 105-137ms per spawn against 3.4ms per builtin -- names the foldable spawn budget, the two commands to keep, and the Defender-exclusion lever to measure BEFORE the code change, since it needs no test edit and plausibly dominates it). Also corrected L4's stale suite count ~133 -> ~144 and recorded the first evidence for L4's premise -- mutation testing caught THREE work-005 suites that were green against a broken subject, each because the broken and the correct reading agree on ordinary data.
  - 2026-08-05: W4-2 + W4-4 RESOLVED and removed (`82e2a267`); W4-1 RESOLVED and removed (`4902af12`). W4-4's fix was verified against the pre-change module as a control (OLD `06/06/2026 20:01:03` vs NEW `2026-06-06T20:01:03Z`), and its oracle gap closed -- the parity suite's `manifest_normalize()` had stripped `installed_at` before diffing, so the field had no guard at all; the new shape assertions ship with a positive control because an assertion that a detector returns `""` passes vacuously when the detector breaks. W4-2 was fixed at BOTH tag-creating suites, not only the one the entry named. Open W4 debt is now W4-3 (Windows suite portability, deferred to its own work) and W4-5 (KB freshness inert, needs a per-document approval decision before any code).
  - 2026-08-04: work-004 closing pass -- added W4-4 (PowerShell `Write-AidManifest` corrupts every ISO-8601 `installed_at` stamp it preserves, because `ConvertFrom-Json` coerces the string to a `[DateTime]` that then interpolates in the current culture's short format; one-way, so the damage freezes in place). Surfaced from a single [LOW] manifest row and traced to the producer by experiment; the remediation the obvious reading suggests (`-AsHashtable`) was checked and does NOT work. Also corrected W1-11, which predicted a corpus shrink to 74 where the live figure is 75 and contradicted four other primary docs -- and, since work-004 has now landed, rewrote it from a prediction into the residue that actually remains (kb.html, plus W1-2's prose populations), naming the structural reason neither is machine-guarded.
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
| **L4** | Test-effectiveness gap | No systematic measure of test-suite **effectiveness**. Line-coverage `%` is (still) rejected as the wrong tool for a mostly-non-instrumentable product (see `decisions.md` D26), but the AID-appropriate measures — mutation testing, invariant-anchoring, behavioral-surface coverage, escaped-defect tracking (dogfooding is already in place) — are not yet implemented as a program. Nothing today tells us whether the ~144 suites actually *bite*. Partial, non-programmatic progress since: work-005's graph suites carry mutation matrices behind `--self-mutate`, and mutation caught **three** suites that were green against a broken subject — in each case because the broken and the correct reading agreed on ordinary data, which review cannot see. That is evidence for the approach, not a substitute for the program. | whole test suite / CI | **High** | M (phased) | **P1 — next release** |

**Risk definitions:** High = active risk to reliability/security/maintainability of core
flows; Medium = growing cost, becomes high if unaddressed in 1-2 cycles; Low = known, not
urgent.

---

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| **W1-1** | Third-party integration bug | `astro-mermaid` never forwards a **top-level** `themeVariables` to `mermaid.initialize` — it destructures only `{theme, autoTheme, mermaidConfig, iconPacks, enableLog}` and builds its client config as `{startOnLoad:false, theme, ...mermaidConfig}`, so a palette passed one level too high is silently dropped. **⚠️ DO NOT "fix" this by nesting the palette under `mermaidConfig`.** That forwards it successfully and thereby pins **one** palette across **both** themes `autoTheme` switches between, so the dark colours bleed into light mode — strictly worse than the inert palette. AID's resolution was to **delete** `themeVariables` and move per-theme colour to CSS, where `[data-theme]` can select (`site/src/styles/casulo.css`, mermaid block); `mermaidConfig` now carries layout only, which is theme-independent and safe to fix there. So the site is correct today and this row records only the **upstream** gap, in case a future need for config-level theming arises. Independently mitigated: generated charts emit a self-contained `classDef` block, so they are legible either way. | `site/astro.config.mjs`:35-42 (the warning, inline at the site) vs `astro-mermaid-integration.js`:229-235 | Low | S | P3 |
| **W1-2** | Stale KB facts | `module-map.md` § Skill Structural Shapes states its per-shape populations as hand-measured prose instead of deriving them, so they go stale at every corpus change — the section has been corrected once and re-measured again after the alias removal, and it tells its own reader to re-verify against a fresh scan before trusting the split in tooling. Two independent scans agreed on the inline-state population but differed on the doorway/residual split. The live figures belong in the generator's `shapeCounts` manifest entry (`site/scripts/gen-skills.mjs`), not in prose — the row should be regenerated from it or lose its numbers. | `.aid/knowledge/module-map.md` § Skill Structural Shapes | Low | S | P3 |
| **W1-3** | Graceful-degradation gap | Client-side mermaid rendering means a reader without JavaScript sees raw `flowchart TB …` source inside an animated placeholder. Accepted at design time (the below-chart ordered list is static markdown and carries the same information), but it now affects all 75 skill detail pages rather than 4. | `astro-mermaid-integration.js`:64, 316-318 | Low | M | P3 |
| **W1-5** | Extractor gap | The `X (optional) then Y` advance form is not split by the flow extractor, so a state carrying it renders one edge where two are meant. | `site/scripts/lib/flow-graph/advance.mjs` | Low | S | P3 |
| **W1-6** | Stale curated roster | `SKILL_GROUPS` files `aid-triage` under *Definition* where FR-5 puts it in *Support*. No longer rendered anywhere, but still read by the corpus drift guard, by `skill-counts.mjs`'s `curatedOnly`, and by the derived grouping-divergence note on `/skills/` — so correcting it is a real change with real consequences, deliberately not folded into delivery-006. | `site/scripts/skills/curated-roster.mjs` | Low | S | P3 |
| **W1-7** | Misleading signal | `data-processed` on a mermaid container means "render attempted", not "SVG present" — an error `<div>` also carries it. Consumers must check for an actual `<svg>`. | `astro-mermaid-integration.js` | Low | S | P3 |
| **W1-8** | Missing re-entrancy guard | `initMermaid()` has no re-entrancy guard, so rapid theme toggling can interleave two render passes over the same container. | `astro-mermaid-integration.js` | Low | S | P3 |
| **W1-9** | Contradictory templates | The two task templates disagree with each other, and one claims a conformance property it does not enforce. | `canonical/aid/templates/delivery-plans/` | Low | S | P3 |
| **W1-10** | Environment trap (Windows) | Worktrees for this repo must be created with **Windows git**, never WSL git — a WSL-created worktree produces paths the Windows toolchain cannot resolve, and the failure is confusing rather than immediate. | process / dev environment | **Medium** | — (documented) | **P2** |
| **W1-11** | Cross-work collision (residue) | work-004 shrank the corpus (111 → 75 directories) and renamed skills, so the collision this row *predicted* has now happened and what remains is residue, not risk. The machine-derived half is **discharged**: `tests/canonical/check-skill-counts.mjs` derives every guarded count from the one derivation and exits 0 over the live corpus — today **76 skills**, stated here in a phrasing that guard reads, rather than in one it cannot see and that would drift the way this row's previous figure did. The hand-written half is **not** closed, and two survivors are known. `kb.html` still states the old corpus total in three places and **cannot be regenerated** — the assembler's `.aid/.temp/summarize/` input tree no longer exists — so it was left stale by explicit owner decision rather than oversight. And `W1-2`'s hand-measured per-shape populations are still prose. Neither survivor is machine-guarded: the count guard's file filter admits only markdown, shell, JS/TS, Python and YAML extensions, so it structurally cannot see an `.html` file. Re-derive the live figure (`ls -1d canonical/skills/*/`) before trusting any prose enumeration. | `.aid/knowledge/kb.html`; `.aid/knowledge/module-map.md` (see W1-2) | **Medium** | M | **P2** |
| **W1-12** | Intermittent rendering defect | ELK layout is intermittently not applied — diagrams fall back to dagre routing, producing the curved, overlapping edges the owner explicitly rejected at the delivery-003 UI checkpoint. `layout: 'elk'` is present and the loader registers; two hypotheses remain live and untested. **Owner-deferred**, shipped open and disclosed. | `site/astro.config.mjs`:47 + `@mermaid-js/layout-elk` | **Medium** | M | **P2** |
| **W1-13** | Accessibility gap | The node-detail panel is a `div[tabindex="-1"]` with **no `role` and no accessible name** — the accessibility tree shows it as `generic`. Activation moves focus into it, so what a screen reader announces on arrival is not deterministic across NVDA / JAWS / VoiceOver. It does carry an `<h3>` naming the step and a labelled close button, so the content is reachable; the framing is what is missing. Fix is `role="region"` (or `dialog`) plus `aria-labelledby` pointing at the existing `<h3>`. | `site/public/skill-node-panel.mjs` / `site/src/lib/skill-node-panel.ts` | Low | S | P3 |
| **W1-14** | Invalid ARIA | Every decorated node carries `aria-controls="aid-node-panel"` from page load, but the panel is created **lazily on first activation** — so before any node is activated the attribute references an element that is not in the DOM. Confirmed on a fresh load: `document.getElementById('aid-node-panel')` is null while 5 nodes already advertise it. `aria-controls` is specified to reference an existing element. | `site/public/skill-node-panel.mjs` | Low | S | P3 |
| **W1-15** | Unperformed verification | The **screen-reader announcement** check has never been run against a real screen reader. The work-level final gate verified the mechanism (accessibility tree + focus movement) in Chromium, which is not the same thing as the utterance. Needs one NVDA or VoiceOver pass over a skill detail page's chart. Tracked because the check is named in `REQUIREMENTS.md` and in feature-006's blocking default, and a mechanism inspection was substituted for it. | process / manual QA | Low | S | P3 |
| **W4-3** | Test-suite portability (Windows) | **The red count depends on HOW the suites are run, and both figures are real — quoting either one alone has already caused two contradictory measurements to be filed as a disagreement.** Under `tests/run-all.sh` (per-suite `timeout 300`, ~22-way concurrency on this host) **34 fail**. Run **individually with adequate time**, only **23 fail** — the other **9 carry no assertion failure at all** and merely run out of clock under contention. Confirmed by counter-example: `test-frontmatter-lint.sh` is a named member of the environmental red register, yet standalone it is `rc=0`, 57 passed / 0 failed. So 34 measures the *harness budget*, 23 measures *actual portability defects*, and the 9-suite delta is the harness, not the code. A related trap in the register itself: its enumeration is written with quantifiers ("the three `dashboard*` suites") that a glob over-expands — anchored expansion gives **40** files where the literal enumeration sums to 35. Diagnosed 2026-08-04, per suite, with root causes rather than a blanket "environmental" label. Five defect classes: **(A)** POSIX path inside a code string passed to a native tool — 29 sites; note MSYS *does* convert paths in argv, so only in-string paths are affected; **(E)** `chmod`-to-deny is a silent no-op on this filesystem, so negative-permission fixtures never deny — 28 sites, test fixtures only, product has no chmod-deny call; **(F)** fixtures stub only the POSIX `bin/aid` while `os.name == 'nt'` correctly takes the pwsh branch, so `pwsh -File <missing>` exits 64 — ~51 assertions; **(G)** pyenv-win's `python3` shim is a shell script routed through `cmd /C`, which cannot carry an embedded newline, so any multi-line `python3 -c` script is mangled — 47 sites, **the load-bearing one being `find_free_port()` returning an empty string**, which is the first failure in 6 suites including all 31 of `test-aid-remote`'s cascade; **(H)** dependence on local `origin/master` ancestry. **76 of ~80 non-timeout defect sites collapse into two helper functions** — that is the number that makes this tractable. Separately, 9 suites emit **zero** assertion failures and simply exceed the per-suite `timeout 300`; that is a real performance redesign, not a timeout bump (`test-aid-cli.sh` does not finish in 562 s — it forks `basename` once per file across the whole rendered profile tree before its first `echo`), and fixing it **raises** the visible failure count by exposing 19 latent class-E sites. Genuinely CI-only: **2 assertions**, not 2 suites. Sized at **12 distinct pieces: 6 mechanical, 2 design, 1 perf redesign, 3 open investigations** — the largest unknown being ~50 assertions across `test-release` / `test-release-install-e2e` sharing a `release.sh --dry-run` exit-1 root that did not reproduce outside the suite's own `make_clone`. Environment-agnostic is achievable for essentially all 23; it is not achievable cheaply, which is why it is a work of its own and not a delivery bolted onto work-004. | `tests/lib/net.sh`:27 and `tests/canonical/**` (per-class site lists to be re-derived at pickup — the 2026-08-04 sweep lived in a scratchpad, deliberately not cited here) | **Medium** | L (phased) | **P2** |
| **W4-5** | Unusable freshness signal (KB data, not code) | The KB freshness reporter can never say `current` or `suspect` for any document, because **not one of the 16 KB docs carries an `approved_at_commit:` key** (`git grep -nE '^approved_at_commit:' -- .aid/knowledge/` returns nothing; positive-controlled against `kb-category:`, which matches 21 lines). Source-drift-versus-approval is the property the reporter computes, so with no approval baseline every doc resolves to `unknown (no approved_at_commit)` and the whole signal is inert. **This is a data gap, not a script defect** — a distinction worth preserving, because the obvious reading blames the script: it does *not* falsely report success, it honestly reports "I cannot tell", and exit 0 means only "the scan completed". Its contract is deliberately reporter-not-oracle (read-only, no file writes, `suspect` a normal verdict), depended on by 16 `FR*` assertions and by `test-conformance-lane-semantics.sh` CL30-CL32, so an assertion must not be bolted into it — and its stdout is load-bearing: `FR14` counts lines matching any of the three verdict words and asserts parity with the TSV row count, so any added summary line naming a verdict breaks the suite. Closing this needs a semantic decision per document (which commit approves it?) back-filled via `migrate-kb-frontmatter.sh`, which is why it is not a mechanical fix. **Separately and independently:** no committed test asserts that the generated `.aid/knowledge/INDEX.md` is reproducible from its source. It currently *is* — verified by rebuilding into scratch and diffing — but a plain diff cannot be the assertion, because exactly three embedded-timestamp lines always differ (the `changelog:` generated date, the `AUTO-GENERATED` comment, and `Generated at:`); masking those three yields a clean diff, and a mask-defeat control (mutate content, then mask) still fails, so the mask does not hide real drift. That assertion belongs in `tests/canonical/test-build-kb-index.sh` with a `coverage-baseline.tsv` row, not in the reporter. | `.aid/knowledge/*.md` frontmatter (16 docs); assertion gap at `tests/canonical/test-build-kb-index.sh` | Low | M | P3 |
| **W5-1** | Incomplete convention rollout | `tests/canonical/select-suites.sh` runs only the suites a change set can affect, but selection is only as narrow as the manifests present: a suite with **no `# COVERS:` header is treated as covering everything and is always selected**. Only work-005's committed `test-graph-*.sh` suites carry one, so the remaining **~135** suites are all selected fail-safe on any change and `--glob` is currently required to keep the output useful. The mechanism is correct but narrow until `COVERS` is promoted across `tests/canonical/`. Deliberately fail-safe in this direction: forgetting a header costs time, never coverage, so an incremental rollout is safe and can be done a family at a time. The one way to lose coverage is a **wrong** entry, so each line is reviewed as a claim about the suite it sits in. **Do not "fix" this by making a missing header mean "covers nothing"** — that inverts the failure mode from wasted time to silently skipped suites. | `tests/canonical/select-suites.sh` + the ~135 suites without a `# COVERS:` block | Low | M (phased, per family) | P3 |
| **W5-2** | Local performance (process spawn budget) | `canonical/aid/scripts/graph/scan-source.sh` takes **~9.8s to scan a two-file repository**, flat across runs, because ~8.4s of it is **~100 external process spawns** — on a Windows/MSYS shell a spawn measured **105-137ms** against **3.4ms** for a bash parameter expansion. Wall time therefore tracks spawn count, not input size. Measured spawn budget: `sort` 23, `awk` 14, `tr` 10, `wc` 6, `cut` 5, `grep` 5. Dedup-only sorts become `awk '!seen[$0]++'` (no spawn), consecutive `awk` stages fold into one program, and `wc`/`cut`/`grep` fold into a neighbouring pass; `dirname`/`realpath` become `${p%/*}`. **Keep `xargs`** — it is the batching mechanism, not the problem — and keep `mv` for atomic writes. **Check the environment lever first and measure it:** Defender real-time protection scans each process image at creation, and on the machine measured `Get-MpComputerStatus` reported it enabled with `ExclusionPath` holding a single empty entry, while `C:\Program Files\Git\usr\bin` holds 249 executables that every pipeline stage relaunches. Excluding the repo root and the Git/node toolchain needs no code change and plausibly dominates the code fix. **This is a developer-loop cost, not a shipped-product defect** — the same spawns cost well under 1ms on Linux CI — so it is sized against the test loop it slows, not against adopter-facing performance. | `canonical/aid/scripts/graph/scan-source.sh`; dev environment (AV exclusions) | Low (product) / **Medium** (dev loop) | M | P3 |
| **W5-3** | Unparseable data + a gate that cannot see it | **6 of the 21 KB documents have frontmatter that is not valid YAML** — `decisions.md`, `infrastructure.md`, `integration-map.md`, `module-map.md`, `tech-debt.md`, `test-landscape.md` — all with one root cause: a `changelog:` entry is a single-key mapping (`- <date>: <prose>`), and where that prose contains a `": "` the parser reads a second mapping value and rejects the line (e.g. `` carried a `release: published` trigger ``). **The reason it went unnoticed is the more useful half of this row: nothing checks it.** `test-frontmatter-lint.sh` passes 57/0 because `lint-frontmatter.sh` validates *field presence* and *list-versus-scalar shape* textually, never well-formedness — and its FL19 class asserts that AID's own KB docs **soft-skip** entirely. So the one gate named after frontmatter is structurally blind to frontmatter that will not parse. **Currently latent, not breaking:** no consumer YAML-parses these files — the scripts that read `.aid/knowledge/` (including work-005's graph scripts) use grep/sed — so the damage is a trap, not an outage. The first tool that reaches for a real parser fails on 6 of 21 docs. **Fix carefully:** quoting the offending scalars (or making them block scalars) changes no prose and is safe, but these are *historical audit entries* and this document has already had a dated Change Log row falsified by an in-cycle edit, so the fix must be quoting-only, never rewording. The durable fix is an assertion — one `yaml.safe_load` per KB doc — which belongs with `test-build-kb-index.sh`'s reproducibility assertion (see W4-5) rather than inside the reporter. | `.aid/knowledge/*.md` frontmatter (6 of 21); gate gap at `tests/canonical/test-frontmatter-lint.sh` FL19 + `lint-frontmatter.sh` | Low (latent) | S (quoting) + S (the assertion) | P3 |
| **W5-4** | Test-harness cost defect (a rule broken by its own neighbour) | The mutation harness is an **~8x multiplier** on an already-slow suite because `test-graph-source-enumeration.sh:1112` runs each mutant as `bash "$SELF"` — **a full re-run of the whole suite** (189 assertions, 5 subject scans) per mutant. **MEASURED end to end: 1,040s (17.3 min) for one suite** (7 mutants, 7 killed, 0 survived), against an arithmetic prediction of ~584s from baseline 73s x 8 — so the real cost is **~1.8x the arithmetic**, because a mutant run pays the whole suite's fixture construction as well as its 5 scans. That measurement was taken while a second suite job held CPU, making it an upper bound under contention; the honest range is ~584-1,040s and the measured end is the one to plan against. Either way ~40 subject scans are spent to test seven one-line defects. Across the six committed suites at measured times that is `(196+79+73+58+29+25) x 8 ~= 3,680s ~= 61 min` per deliverable — a FLOOR rather than an estimate, since the one suite actually measured came in at ~1.8x its own arithmetic; observed consequence, two builders spent the bulk of a 2.5-hour run inside mutation loops. **This directly violates S1** ("invoke each subject once per distinct input") which sits three rows above S3 in the same table — the convention was written and then not applied to the harness implementing its neighbour. **Fix, in payoff order: (1)** a mutant runs only its target assertion GROUP, never the suite — T6's group filter already exists for exactly this; **(2)** library-level mutants call the function directly with no pipeline scan (M3/M4 mutate `SIG_RANK` and the evidence selector in `significance-rules.sh`, pure shell functions needing zero scans); **(3)** mutants sharing a fixture share one scan. Expected ~511s -> ~60-90s per suite. **DO NOT resolve this by dropping mutants.** The matrix is the only oracle that caught three suites which were green against a broken subject — a gap-ledger reading node kinds from an id prefix past 294 assertions, three validator assertions checking for absence of a message a broken validator also never emits, and an assertion that a gitignored `.pyc` is absent from output it could never reach. In every case the broken and the correct implementation agree on ordinary data, which is invisible to review. Scope note: S3 has been narrowed so a matrix is required only where an assertion CAN be vacuous (absence, universals, derived invariants), which removes most of the multiplier without losing those catches. **MEASURED 2026-08-05, during work-005 wave-1 execution, and the number is worse than 'incomplete':** `146` suites in `tests/canonical/`, of which **11** carry a `# COVERS:` header and **135** carry none -- so 135 are fail-safe-selected for *every* change. Found by task-030 running `select-suites.sh --run` after touching `read-setting.sh`: it selected **140 of 146** suites (only 5 declare that path). That is the full canonical suite in disguise, i.e. the selector currently delivers **no** saving for the common case and silently costs the caller the whole run when they believe they are running a subset. The executor correctly abandoned it and grepped for real `read-setting.sh` references instead (15 test files, 5 production callers) -- which is the workaround every caller will independently reinvent until the headers land. **The tool is correct; the DATA is missing, and the fail-safe default converts missing data into a silent full run.** Consider making `--run` print the selected/total ratio and warn above a threshold, so a caller can see they are getting a full run rather than a subset. | `tests/canonical/test-graph-source-enumeration.sh`:1100-1128 (`run_mutant`), and any suite copying that harness | Low (correctness) / **Medium** (dev loop + agent run cost) | S-M | **P2** |
| **W5-5** | Silently-failing state write across the whole pipeline | **Every pipeline-phase state write in the methodology fails, and fails invisibly.** `writeback-state.sh` defaults its target to the placeholder `.aid/works/work/STATE.md` (`:191`) and expects the caller to export `AID_STATE_FILE`; **14 reference files across 7 skills** invoke `writeback-state.sh --pipeline` and **not one** exports it — `aid-define` (1), `aid-deploy` (2), `aid-describe` (2), `aid-detail` (1), `aid-execute` (3), `aid-plan` (1), `aid-specify` (4). Each call exits 1 with `ERROR: ... .aid/works/work/STATE.md does not exist`, and because the snippet is documented as "silent state-write only — no output, no gate", **nothing surfaces**. `AID_WORK_DIR` does not help: `--pipeline` targets `STATE_FILE`, which honours only `AID_STATE_FILE`, and the script's own comments at `:1329-:1336` record someone hitting that confusion from the other direction. **Observed consequence, which is how it was found:** work-005's `STATE.md` sat at `phase: Specify` / `active_skill: aid-specify` / `updated: 2026-07-31` for days after Specify finished, and had to be corrected by hand. **This defeats the tracking discipline `CLAUDE.md` declares IMPERATIVE** — the phase field is only ever right when a human notices it is wrong. Fix is one line per call site (export `AID_STATE_FILE` from the work id the skill has already resolved), but the *durable* fix is to make the failure loud: a `--pipeline` call whose target does not exist should be a hard error the calling state surfaces, not a swallowed exit 1. Consider also dropping the placeholder default entirely so an unscoped call cannot silently address a non-existent work. **SECOND INSTANCE, same shape but a DIFFERENT env var, found by running `/aid-execute` on work-005 delivery-001 (2026-08-05).** The *task*-state write path -- `writeback-state.sh --delivery-id DDD --task-id NNN --field State --value V` -- resolves through `WORK_DIR`, which honours `AID_WORK_DIR` (`:195`, `resolve_work_dir` `:227-:230`), **not** `AID_STATE_FILE`. It carries the same placeholder default, so every such call made exactly as documented fails with `ERROR: ... .aid/works/work/deliveries/delivery-001/tasks/task-NNN/STATE.md does not exist`. **What makes this worse than the `--pipeline` half: these are the writes the skill declares MANDATORY in its loudest terms.** `aid-execute/references/state-execute.md` `:13-:24` gives the "full runnable form" and a four-row transition table, `:313-:317` (PD-2 step 5) gives the orchestrator's own write, and `:337-:394` (PD-2a) instructs every dispatched sub-agent to make the same calls -- and **not one of those sites exports `AID_WORK_DIR`**. So an agent that follows the mandate verbatim writes nothing, and the protocol's own stated failure mode (a task sitting at `Pending` for its whole execution then jumping to `Done`) is produced *by following the instructions*. Fixing the 14 `--pipeline` sites therefore does not close W5-5: the task-state sites need `AID_WORK_DIR` and are a separate sweep. The "make it loud" half of the fix covers both and is the durable one. | `canonical/skills/{aid-define,aid-deploy,aid-describe,aid-detail,aid-execute,aid-plan,aid-specify}/references/*.md` (14 files); `canonical/aid/scripts/execute/writeback-state.sh`:191 | **Medium** | S (call sites) + S (make it loud) | **P2** |
| **W5-6** | Task-template inconsistencies (four, all verified first-hand) | Surfaced while writing work-005's 29 task files; each was checked against the template bytes rather than taken on report. **(1) The two task templates disagree on the `Source` value AND on its arrow.** `task-detail-template.md:23` prescribes `**Source:** work-NNN-{name} -> delivery-NNN` (ASCII arrow); `delivery-plans/task-template.md:5` prescribes `**Source:** feature-NNN-{name} → delivery-NNN` (U+2192). A reader or parser keying on `work-NNN` in that field misses every feature-scoped task, and one keying on either arrow misses half the corpus. **(2) `task-state-template.md:74-76` ships literal example findings** — `- [CRITICAL] {description} -- {source-file:line} -- Fixed-on-spot` and a `[HIGH]` twin — inside an AUTHORED section. Seeded verbatim these read as **real recorded findings**; work-005's 29 files deliberately carry `--` instead, but nothing in the template says to do that. **(3) The trailing acceptance criterion is self-referential, at five sites:** `- [ ] All section-6 quality gates pass` where section 6 **is** Acceptance Criteria (`task-detail-template.md:33`, `delivery-blueprint-template.md:31`, `shortcut-engine.md:541`/`:617`/`:748`). It cannot be evaluated without circularity, so in practice it is either ignored or treated as a no-op — which is worse than absent, because it looks like a gate. **(4) The six-section schema has no field for a wave or phase grouping** and closes with "Six sections … **Nothing else**" (`delivery-plans/task-template.md:19`), so a work using wave-based gating has nowhere structural to record the wave; work-005 encoded it inside the `Source` line as `-> delivery-001 (Wave N)`, which works but is a convention no template sanctions. | `canonical/aid/templates/task-detail-template.md`:23,33; `canonical/aid/templates/task-state-template.md`:74-76; `canonical/aid/templates/delivery-plans/task-template.md`:5,19; `canonical/aid/templates/delivery-blueprint-template.md`:31; `canonical/aid/templates/shortcut-engine.md`:541,617,748 | Low | S | P3 |
| **W5-7** | Config resolver returns a COMMENT as the value | `canonical/aid/scripts/config/read-setting.sh` silently resolves a comment into a config value. For a **bare `key:` line whose list continues on the following lines**, a trailing inline comment on that key line is returned *as the value*. Reproduced independently with two side-by-side fixtures: `graph:\n  ignore:   # repo-relative globs excluded from node enumeration\n    - examples/**` makes `--path graph.ignore` print `# repo-relative globs excluded from node enumeration`; move the identical comment down onto the `- examples/**` line and it correctly prints `examples/**`. Cause: in `lookup`/`lookup_list` the whitespace-stripping substitution runs first and greedily consumes the space that the comment-stripping substitution needs as its anchor, so the comment survives and the real value is dropped. **Why this is worse than a parse failure:** it does not error, it returns a plausible-looking string, so a caller cannot distinguish it from a real setting -- and this resolver is the methodology-wide settings reader, not a graph-specific one. **How it was found:** feature-004's SPEC `:1609` shows the `graph.ignore` seed with the comment on exactly that bare `ignore:` line, so writing the SPEC's literal layout triggers it. work-005 task-006 moved the comment one line down to route around it and did NOT edit the resolver (out of its declared scope), so nothing shipped is currently broken -- the bug is latent, and the SPEC still shows the triggering layout. No suite covers it: `test-read-setting.sh` passes 19/19. | `canonical/aid/scripts/config/read-setting.sh` (`lookup`, `lookup_list`); trigger layout at feature-004 SPEC `:1609` | **Medium** | S | **P2** |
| **W5-9** | Acceptance assertions that SKIP in CI as well as locally -- dead coverage on the load-bearing rendering | **11 of feature-009's DOM-grounded `TV` verdicts never execute anywhere.** `tests/canonical/graph-view-dom.mjs` resolves jsdom by bare specifier (or an explicit `AID_GRAPH_JSDOM` path) and its own header states plainly that jsdom IS NOT A REPOSITORY DEPENDENCY (`:21`). jsdom is declared **only** in `site/package.json` (`:36`, `^29.1.1`) and installed only under `site/node_modules/`; resolving it from the repo root **fails**. CI's `test.yml` runs `bash tests/run-all.sh` (`:73`) with **no install before it** -- the workflow's only `npm ci` sits at `:92` under `working-directory: canonical/aid/scripts/summarize`, a different directory, and runs later. Nothing sets `AID_GRAPH_JSDOM`. So TV04, TV05b, TV06c, TV08b, TV09b, TV10, TV12, TV13b, TV15, TV17 and TV18 report SKIP on every machine and in every pipeline. **The suite is honest -- it reports SKIP and never a false PASS, which is the correct design -- but nothing SURFACES that a third of a feature's acceptance assertions are inert.** A green suite carrying 33 skips reads as a green suite. **Why this is worse than it looks:** task-010 measured the interactive canvas failing NFR-7 by ~2.8x at the median, with NFR-8's ceiling at (500,550] against a 1,609-node bench, and `graph-controls.js:883` mounts the table **first and unconditionally** -- so the accessible table is the rendering that actually works at this project's scale, and it is precisely the one whose DOM assertions do not run. The narrow fix is small (make jsdom resolvable to the canonical suites in CI, or set `AID_GRAPH_JSDOM` in the workflow); the DURABLE fix is a floor -- a suite whose named acceptance ids all skip, or whose skip count crosses a threshold, should FAIL rather than pass. | `tests/canonical/graph-view-dom.mjs`:21,:147; `site/package.json`:36; `.github/workflows/test.yml`:73,:90-92; `tests/canonical/test-graph-table-view.sh` (33 skips alongside 116 passes) | **High** | S (resolve jsdom) + S (skip floor) | **P1** |
| **W5-10** | A specified, twice-assigned deliverable that no task owns -- the FIFTH instance of this class in one work | **feature-007 requires AC-6's runtime prerequisites in TWO carriers and only one was ever built.** SPEC `:1604`-`:1608`: "The generator emits, into the page footer *and* the run's console summary: whether a network is required, which companion files must travel with the entry point, whether a build output is involved, and ... that a **working WebGL context** is required for the live graph, with the statement that the table view remains fully usable without one." `:1817` (GV23) repeats it: the footer **and** the console summary **each** state them. On disk, `render-graph-view.sh` emits **nothing at all on a successful run** -- its only `echo`s are the unknown-argument (`:49`-`:50`) and node-missing (`:57`) paths, both stderr, both failures. A sweep of all 30 task DETAILs (task-031 did not yet exist) finds **zero** occurrences of `GV23`; "runtime prerequisite" appears only in `task-011` (type DOCUMENT, emits nothing) and `task-017` (which explicitly EXCLUDES prerequisite messaging). feature-007's IMPLEMENT task, `task-013`, is already Done. `task-023` was the other candidate because `:1604` sits in feature-007's "Packaging and the entry point" section, but `task-023` is sourced from feature-012 and its DETAIL contains no occurrence of console/prerequisite/summary/footer/WebGL/network. **Why this matters beyond the missing text:** the sentence that goes missing is the one telling a reader without WebGL that they have lost nothing -- and on AID's own KB the table IS the working rendering (canvas fails NFR-7 by ~2.8x at median on a 1,609-node bench; `graph-controls.js:883` mounts the table first and unconditionally). **The pattern is the real debt:** all five ownerless obligations in this work were found by an executor DOING the work, never by a reviewer READING it -- Detail-phase review does not detect an obligation carried by no task, because there is no artifact to read. The durable fix is a Detail-phase gate that diffs each feature's acceptance-criteria ids against the union of ids claimed by its tasks. **Implementation half assigned to work-005 task-031** (created 2026-08-06 during wave-3 execution, in the owner's absence, on the task-030 precedent); its oracle already exists and already fails honestly (`GV23b`). | `canonical/aid/scripts/graph/render-graph-view.sh`:49-50,:57 (only echoes, both failure paths); feature-007 SPEC `:1604`-`:1608`,`:1817`; `tests/canonical/test-graph-view-shell.sh` GV23b (failing, correctly) | **Medium** | S (the text) + M (the Detail-phase id-diff gate) | **P2** |
| **W5-11** | A SPEC that contradicts its own cited authority on a load-bearing accessibility invariant | **feature-008's SPEC and feature-007's SPEC assign the graph canvas's attributes to each other.** feature-008 `:462`-`:467` says the `<canvas role="img">` is "fixed by feature-007 (`:1718`)" and that feature-008 "authors no attribute on either element ... ever" beyond width/height -- and its AC-S8/GC09 (`:227`-`:230`, `:645`) are written on that premise. But feature-007 `:1718`, the very line feature-008 cites, says the canvas and its `role="img"`/`aria-label` are **"Owned by feature-008"** -- the opposite assignment. **Shipped code settles which reading is operative, and it is feature-007's:** `graph-skeleton.html:116`-`:120` contains no `<canvas>` at all, only `<div data-graph-surface>`, with a comment stating the drawing rendering "creates its own canvas inside this container and marks it so the shell can keep its text alternative current"; and `graph-controls.js:943` finds the canvas **only** via `[data-graph-canvas]`, a marker no other file in the pipeline can author. **So a literal implementation of AC-S8 as written would permanently break the shell's own aria-label-refresh mechanism** -- the accessibility feature it was shipped to serve. work-005 task-017's executor implemented the operative reading (`role="img"` + `data-graph-canvas`) and documented why; the reviewer confirmed the code is correct and the SPEC is wrong. **Live risk:** `task-018` authors GC09's assertions against AC-S8 and will encode the zero-attribute contract unless the text is corrected first. Needs an owner ruling and a SPEC/DETAIL correction, not a code change. | feature-008 SPEC `:462`-`:467`,`:227`-`:230`,`:645` vs feature-007 SPEC `:1718`; `canonical/aid/templates/knowledge-graph/graph-skeleton.html`:116-120; `canonical/aid/templates/knowledge-graph/graph-controls.js`:943-944; ledger `.aid/.temp/review-pending/task-017-review.md` row 1 | **High** | S (correct two documents) | **P1** |
| **W5-12** | A documented exit code that the code does not produce, on the error path most likely to be hit | `contrast-check.mjs:27` documents "`2  Invocation error (missing file, bad/missing --profile value).`" but a **missing file** does not exit 2 -- it exits **1**, via an uncaught `ENOENT` promise rejection rather than a handled error path. The bad/missing `--profile` half of the same sentence is correct and does exit 2; only the missing-file half is wrong. **Pre-existing and unchanged by work-005 task-019** -- confirmed identical in `HEAD` and in the working tree by running both versions against a nonexistent path. It surfaced only because task-019's acceptance criteria bound the script's documentation to its actual behaviour, and the executor correctly declined to fix it unilaterally inside a FIX cycle scoped to four other rows. **Why it is worth fixing rather than ignoring:** a caller that branches on exit 2 to mean "you invoked me wrongly" will read a missing artifact as a genuine contrast FAILURE, and an uncaught rejection also prints a stack trace where a one-line diagnostic belongs. Either handle the read and exit 2, or correct the header to say 1 -- but the two must agree. | `canonical/aid/scripts/summarize/contrast-check.mjs`:27 (the claim); verified by execution against a nonexistent path on both `git show HEAD:` and the working tree -- exit 1 with an uncaught ENOENT in both | **Low** | S | **P3** |
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
> `new Set(SHAPE_ORDER)` and all 76 sidecars emit. The classification had been read off the
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
The ~76 prompt-driven skills are **out of scope** for these techniques (there is no
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
| 2.6 | 2026-08-05 | work-005 test-strategy update | Opened **W5-3** — 6 of 21 KB docs carry frontmatter that is not valid YAML (a `": "` inside a `changelog:` entry's prose), and the gate named after frontmatter cannot see it because `lint-frontmatter.sh` checks field presence/shape textually and its FL19 class soft-skips AID's own KB docs; latent today because no consumer uses a real parser. Found incidentally while validating this very update, which is the only reason it surfaced. Opened **W5-1** (the `# COVERS:` change-set-selection convention is landed but rolled out only to work-005's graph suites, so ~135 suites are still selected fail-safe and `--glob` is needed — with an explicit warning not to invert the fail-safe direction) and **W5-2** (`scan-source.sh` spends ~8.4s of ~9.8s in ~100 process spawns on a two-file repo, at 105-137ms per spawn against 3.4ms per builtin; names the foldable spawn budget, the two commands to keep, and the AV-exclusion lever to measure first). Corrected **L4**'s stale suite count ~133 → ~144 and recorded the first real evidence for its premise: mutation testing caught three work-005 suites that were green against a broken subject. |
| 2.5 | 2026-07-24 | work-024 test-suite-improvement KB refresh | Corrected **L4**'s stale suite count ~118 → ~133 (live total, matching `test-landscape.md`); no residual-gap row added — the ≤3min/~90s outcome is measured on the post-push CI run, and a later KB-DELTA adds an `L5` row only if the ~90s goal is missed. **L4** remains the sole open item. |
| 2.6 | 2026-07-30 | work-001 delivery-006 gate | **L4** plus **W1-1..W1-12** — the work-001 known-issues migrated out of the transient work folder (two Medium traps among them: a KB row teaching the wrong CI model, and a Windows worktree trap), so L4 is no longer the sole open item |
| 2.8 | 2026-08-04 | work-004 closing pass (deferred LOW findings) | **W4-4** opened — the PowerShell manifest writer silently re-renders every ISO-8601 `installed_at` it preserves into a locale short format, one-way, and the only suite that could see it deletes the field before diffing. Second shipped-code defect this work has surfaced from something first filed as cosmetic (cf. **W4-1**). **W1-11** corrected and re-scoped: its `111 -> 74` was wrong against a live 75 and contradicted four other primary docs, and it read as a forward prediction of a shrink that has since landed. |
| 3.0 | 2026-08-05 | W4-2 + W4-4 fix | **W4-2 and W4-4 RESOLVED and removed from the inventory** (`82e2a267`). **W4-4:** all 5 `Write-AidManifest` preserve-reads now route through `script:Format-AidTimestamp`; 0 unwrapped reads remain. Reproduced end-to-end against the real writer with the **pre-change module from git as the control** — OLD wrote `06/06/2026 20:01:03`, NEW writes `2026-06-06T20:01:03Z` byte-exact — which is the exact dogfood corruption, so the fix is measured rather than argued. Bash writers confirmed needing no lockstep change (`date -u` / text-through-`json.load`). **The oracle was the real work:** `manifest_normalize()` greps `installed_at` OUT before diffing, correctly (writers install at different instants) but leaving the field unguarded, so the one suite comparing both writers was blind to this exact bug. Added `manifest_bad_stamps()` + `PAR029-A05a/b` on SHAPE (writer-independent), and **`PAR029-A05c` as a positive control** — A05a/b assert a detector returns `""`, which passes vacuously if the detector breaks, so the control feeds it a known-corrupt stamp and requires a report. **W4-2:** fixed at **both** sites, not the one the entry cited — `test-release.sh` (`aid-test-clone-*`) *and* `test-release-install-e2e.sh` (`aid-test-e2e-*`); tags registered before creation, removed by the EXIT trap. Measured, not assumed: bash **does** run an EXIT trap on SIGTERM (what `timeout` sends) and adding INT/TERM makes it fire TWICE, and `run-all.sh` uses plain `timeout 300` with no `-k`. Discriminating harness: old shape leaks, new leaks none. Clone semantics deliberately unchanged — a tagless `--local` clone was rejected because no test could be built proving `--local` carries a dangling object, and the tag exists for a documented CI detached-HEAD reason in a suite unrunnable locally (**W4-3**). **Left unfiled, pre-existing:** `Write-AidManifest` emits `PropertyNotFoundException: 'Count'` identically under the pre-change module; it does not block the write and is not W4-4. |
| 2.9 | 2026-08-05 | W4-1 fix | **W4-1 RESOLVED and removed from the inventory** (`4902af12`). Its premise was re-validated against this host before the fix rather than taken from the write-up: all three readers returned the **empty string** on a POSIX path and `2.3.0` via `cygpath -m`, so the false "carriers diverge" was reproduced, not assumed. Fixed with a `_native_path()` helper at the 4 sites, `-m` (mixed) so the result needs no re-escaping inside the quoted code string, and a no-op wherever `cygpath` is absent. Verified where the bug actually manifests: the script exits 0 with all 3 carriers at 2.3.0, and `test-version-sync.sh` runs 45/1. **The 1 red is WF01 and is pre-existing** — 0 test files were touched, the suite is byte-identical to master, and its cause is the *same class inside the test* (`open('${RELEASE_YML}')` → `FileNotFoundError: /c/...`); `release.yml` is valid YAML. Test-side instances stay with **W4-3** class (A). Class swept in product code with a positive-controlled detector (the first detector produced a false all-clear and was rebuilt): of 9 inline native-interpreter calls under `canonical/`/`lib/`/`bin/`, only those 4 embedded a path; `bin/aid`:3190 interpolates drive-type strings and already sets `MSYS_NO_PATHCONV=1`. |
| 2.7 | 2026-08-04 | work-004 Windows-failure diagnosis | **W4-1..W4-3** opened. The diagnosis re-based two figures the project had been carrying. First, the Windows red count is **condition-dependent, not a single number**: 34 under `run-all.sh`'s timeout-and-concurrency budget, 23 when suites run individually — the 9-suite gap carrying no assertion failure at all. Two agents measured these independently and their reports read as a contradiction until the conditions were made explicit; W4-3 now states both, because quoting either alone is what produced the apparent conflict. Second, `test-grade-summary.sh` — logged as an unexplained red at two consecutive delivery gates — **passes** (48/0, rc=0, re-run twice). One genuine shipped-code defect surfaced (**W4-1**), previously mis-filed as a Windows-local test artifact. The remaining suite work (**W4-3**) is deliberately *not* folded into work-004: it is 12 distinct pieces across 5 defect classes, and its cheap majority (76 of ~80 sites in two helpers) sits behind a real performance redesign that would dominate the schedule. |
