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
review-criteria: []  # nothing is true of this doc alone. Its one distinctive risk -- a
                     # resolved item left visible -- is G-03 at the global level, and
                     # restating it here would be a finding under FR-5.
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

---

## Debt Inventory

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| **L5** | Review-loop cost and non-determinism | **A review re-reads the whole artifact on every cycle, and re-decides every criterion by reading it.** Two causes, one mechanism. (a) `reviewer-ledger-schema.md`'s cycle N≥2 workflow ends *"Append new rows as `Pending` for newly-found issues"* — finding NEW issues means re-scanning the whole surface, so every cycle pays a full read. `.aid/settings.yml` records the consequence: five consecutive Large-tier gate cycles each closed ~12 findings and opened ~12, the ledger growing 30 → 43 → 62 → 73 → 85 with no decline in the new-finding rate. (b) Every criterion in `authoring-conventions.md` is verified by a reviewer reading it, every cycle, forever — unavoidable for a semantic criterion, waste for a mechanically decidable one such as `G-07` (every in-scope file resolves to exactly one type), and unreliable: re-derivation varies between cycles. Two complementary remedies, and they interlock — see the detail below. | `canonical/aid/templates/reviewer-ledger-schema.md`; `canonical/aid/templates/reviewer-dispatch.md`; the six `canonical/skills/*/references/reviewer-brief.md`; `.aid/knowledge/authoring-conventions.md` | **Medium** | L | **P2** |
| **L4** | Test-effectiveness gap | No systematic measure of test-suite **effectiveness**. Line-coverage `%` is (still) rejected as the wrong tool for a mostly-non-instrumentable product (see `decisions.md` D26), but the AID-appropriate measures — mutation testing, invariant-anchoring, behavioral-surface coverage, escaped-defect tracking (dogfooding is already in place) — are not yet implemented as a program. Nothing today tells us whether the ~135 suites actually *bite*. No programmatic effectiveness measure is in place for the deterministic machinery. That is evidence for the mutation-testing approach, not a substitute for the program. | whole test suite / CI | **High** | M (phased) | **P1 — next release** |
| **L6** | Documentation drift | **Two producer documents still write the legacy KB-baseline key.** The dashboard reader scans `knowledge:` first and falls back to the `kb_baseline:` block only for pre-migration settings files, naming it legacy in `parsers.py` (`parse_kb_baseline`, still named after the block it no longer prefers). But `aid-discover`'s `state-done.md` instructs writing `kb_baseline: {branch, tip_date}` (7 mentions, `knowledge:` 0) and `aid-housekeep`'s `state-summary-delta.md` re-stamps `kb_baseline.tip_date` (5 mentions, `knowledge:` 0), while `aid-config`'s settings table attaches those same FR35/FR36 numbers to `knowledge.{source,last_update}`. The producers and the config schema disagree about which key those two requirements write. Nothing is broken today because the reader accepts both, and `read-setting.sh` resolves neither `kb_baseline` path at all. | `canonical/skills/aid-discover/references/state-done.md`; `canonical/skills/aid-housekeep/references/state-summary-delta.md`; `canonical/skills/aid-config/SKILL.md`; `dashboard/reader/parsers.py:parse_kb_baseline` | **Low** | S | **P3** |
| **L9** | Unguarded drift, and a parser with no consumer | **Nothing now checks the repo-root README's mermaid diagram against the site home page's, and the machinery that used to do it is still here.** The old cross-document guard was retired, not repaired, because the two diagrams stopped answering the same question: README's was replaced with a "Start Here" onboarding flow while `index.mdx` kept the technical pipeline view, so they share zero node labels. Retiring it leaves two residues. (a) The two can drift apart in phase names, skill names, or lite-path shape with nothing to notice -- acceptable for topology, which they are meant to differ on, less so for VOCABULARY, where a phase renamed in one and not the other is a plain error. The stated replacement is a narrower guard on shared vocabulary; it does not exist. (b) `parseFlow` and its 17-case link-grammar suite survive with no caller outside their own tests -- kept deliberately, because that replacement would parse the same diagrams, but dead weight if it is never written. Resolve by writing the narrower guard, or by deleting the parser and its suite and accepting (a). | `README.md` (the mermaid block); `site/src/content/docs/index.mdx` (the mermaid block); `site/src/data/__tests__/ac13-version-injection.test.ts` (`parseFlow`, `AC5 — Home pipeline diagram`) | **Low** | S | **P3** |


| **M5** | Unverified support claim (Python floor) | **The PyPI package promises a Python floor that nothing tests, and that floor is itself past end of life.** `packages/pypi/pyproject.toml`:10 declares `requires-python = ">=3.8"`, while every CI lane pins `python-version: '3.11'` — seven pins across four workflows (`test.yml`:52,:120; `release.yml`:83,:201,:323; `installer-tests.yml`:59; `coverage-parity.yml`:68). So the four minor versions between the promise and the test (3.8, 3.9, 3.10) are exercised by nothing: a user installing `aid-installer` on any of them receives a package whose compatibility was never demonstrated, and a syntax or stdlib feature newer than 3.8 would land green through CI and fail only on their machine. Python 3.8 additionally reached end of life in October 2024, so the declared floor is both untested and unsupported upstream. Six documentation statements repeat the `>=3.8` claim to users (`README.md`:120; `docs/install.md`:51,:105,:852; `docs/faq.md`:55; `docs/aid-methodology.md`:1416), which is how a fictional floor becomes a support commitment. **Fix:** raise the declared floor to the version CI actually runs and move both together thereafter, so the promise and the evidence cannot drift apart again. Note this is a **breaking change for PyPI-channel users** and touches the installer, the profile renderer, and the dashboard reader — it deserves its own change rather than riding along with a feature. | `packages/pypi/pyproject.toml`:10; `.github/workflows/{test,release,installer-tests,coverage-parity}.yml`; the six doc statements above | **Medium** | S | **P2 -- when convenient** |
| **W5-19** | Untrustworthy gate provenance | **The two coverage-parity baseline files can be committed out of step with each other, and nothing detects it -- the committed pair WAS out of step, so the gate's own staleness warning could not be trusted.** `tests/coverage-baseline.meta` records `commit_sha` (written by `git rev-parse HEAD` on the runner, `tests/coverage-parity.sh`:265), while `tests/coverage-baseline.tsv` holds the assertion inventory. When the two files are produced by different runs the sha is unreliable. **Why it matters more than a wrong comment:** the `diff` subcommand compares the recorded sha to HEAD and prints "the diff may be comparing against a stale baseline" (:372-373), and that WARN is what a reader uses to decide whether a reported reduction is real. With the sha unreliable the warning is noise in both directions -- it fires when the baseline is fine and stays quiet when the pair is mismatched. It is also how 12 reductions on PR #178 came to look like lost coverage when every one was a collection artifact. **Fix:** make the pair inseparable rather than asking a human to keep two files in step -- have `collect` stamp the same run identifier into both, and have `diff` refuse to run when the two disagree. A cheap partial that needs no format change -- `diff` fails when a suite named in the baseline is absent both from disk and from the accept list, which catches a split pair whose tsv is ahead of its tree. | `tests/coverage-parity.sh`:264-265 (the meta writer), :372-373 (the WARN that reads it); `tests/coverage-baseline.meta` | **Medium** | S | **P2 -- when convenient** |
| | | *The three rows below are numbered from 18 because `W<n>-` names a WORK, and two different works have each occupied `work-001` -- the earlier one shipped and its folder was pruned, and the number was reused. So `W1-` does not identify a work, and these numbers are unique only within this document. Continue from the highest `W1-` present rather than restarting at 1.* | | | | |
| **W1-18** | Corrupting writer | **`writeback-state.sh` clears a multi-line folded scalar by rewriting only its key line, orphaning the body and leaving the file unparseable.** Setting `Lifecycle` to anything other than `Paused-Awaiting-Input` clears `pause_reason` (`writeback-state.sh`:1821-1823 calls `wb_set_kv ... scalar "--"`), but `wb_set_kv` replaces the `pause_reason: >-` line without consuming the indented block that belongs to it. The result is `pause_reason: --` followed by orphaned indented prose, which every YAML parser rejects with `mapping values are not allowed here`. **Reproduced THREE times on `work-001`'s `STATE.yml`** across a single session: entering `/aid-plan`, closing `/aid-detail`, and entering `/aid-execute` -- each a routine `--pipeline --field Lifecycle` write, each leaving the file unparseable, each repaired by hand. The third occurrence was predicted in the commit that filed the second, which is the clearest possible evidence that this is a systematic defect in the writer rather than a one-off: the only way to avoid it is to stop using the prescribed writer for any key that might hold a block scalar, which is not a workaround anyone will remember. **Any key whose value may be a folded or literal block is exposed**, not just `pause_reason` -- `block_reason` and `block_artifact` take the same path. | `.cursor/aid/scripts/execute/writeback-state.sh`:1821-1823 and `wb_set_kv`; `canonical/aid/scripts/execute/writeback-state.sh` (the authored source the profiles render from) | High | S | High |
| **W1-19** | Test that fails on uncommitted work | **`test-aid-migrate-trigger.sh`'s ISOL-01 cannot tell scratch left by the test from a developer's in-progress edit, so it fails for anyone editing `packages/npm/`.** The check is `git status --porcelain packages/npm/` must be empty (`test-aid-migrate-trigger.sh`:973), intended to catch scratch files the TRG-G/H/I node runs might leave behind. But `packages/npm/scripts/vendor.js` is a real source file that lives under that path, so any legitimate uncommitted change to it fails the suite until it is committed -- which inverts the normal workflow, where tests are how you check work BEFORE committing it. Observed while wiring the chat node into `vendor.js`: the suite failed on the edit and passed unchanged once committed. The check wants the set of files the run CREATED, not the set that differs from `HEAD`: snapshot `git status` before the TRG section and diff against the snapshot after, or restrict the assertion to untracked files (`--porcelain` lines starting `??`). | `tests/canonical/test-aid-migrate-trigger.sh`:969-978 | Medium | S | Medium |
| **W1-20** | Criterion verified against a proxy | **A surface-boundary criterion is verified against the CLI's verb list rather than the artifact it is actually about.** The agent-facing surface is a *skill that omits things*; the criterion asks that the surface gain exactly the roster and the connect request. The skill does not exist yet, so verification stands in the CLI's plane-verb set, which is a PROXY: it can show no administrative verb entered the CLI, and cannot show what the skill will document. Left as a proxy, the real check is never performed, because nothing re-opens a criterion already ticked. | `tests/canonical/test-chat-node-hub.sh` HP19/HP20; the skill when it is authored | Low | Small | Medium |

**Risk definitions:** High = active risk to reliability/security/maintainability of core
flows; Medium = growing cost, becomes high if unaddressed in 1-2 cycles; Low = known, not
urgent.

---

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| **SY-1** | Stale detection signal (carried, not fixed) | `cleanup-classify.sh`'s signal (ii) and its informational status-note reader scan a work's state file for a `> **Status:**` top-level blockquote and a `## Deploy Status` markdown heading -- neither is emitted by the current per-work state template (the equivalent data lives under the `deploy:` AUTHORED key, one entry per delivery, with no such blockquote or heading at all). The staleness pre-dates the current state-file format and is unchanged by it: signal (ii) and the status-note both already degraded to `fail:`/empty against a current-shape work before this conversion, and they still do after it -- repairing either would be an observable behavior change outside a `restructure`'s scope. Routed here rather than silently carried. | `canonical/aid/scripts/housekeep/cleanup-classify.sh` (`compute_signal_ii` -- the `> **Status:**` scan; the `## Deploy Status` scans in `compute_signal_i` and the branch/SHA lookup) | Low | S | P3 |
| **SY-2** | Fail-open safety guard on a missing file (carried, not fixed) | `dashboard/scripts/delete-pipeline.sh`'s `_frontmatter_value` helper returns empty output for a state file that does not exist at all (`[[ -f "$file" ]] \|\| return 0`), and the `Running`-lifecycle deletion guard fires only on an exact string match against that (possibly empty) value -- so a work folder with **no state file** has always been, and remains, deletable with no guard at all. The guard itself was retargeted to the current filename and keeps firing correctly for a `Running` work (the property its own test suite asserts); the narrower missing-file case is pre-existing and unchanged -- hardening it would be an observable behavior change outside a `restructure`'s scope. Same disposition as SY-1 above. | `dashboard/scripts/delete-pipeline.sh`:166 (the `_frontmatter_value` existence check), `dashboard/scripts/delete-pipeline.sh`:346-348 (the `Running` guard it feeds) | Low | S | P3 |
| **SY-3** | Detail-view parsers scan for sections the current template never emits (carried, not fixed) | The work-level `parse_quick_check_findings` / `parse_delivery_gate` detail-view parsers (Python + the Node twin) were retargeted to read `quick_check` / `delivery_gate.{grade,reviewer_tier,gate_timestamp}` keys, but those keys never appear in the document `state_text` these two functions are actually called with: `quick_check` exists only in a per-task file (absent on the flattened Lite path, where there is no such file at all), and `delivery_gate` on the work-root document carries only `issue_list` (the grade/tier/timestamp instead live as top-level `gate_grade`/`gate_tier`/`gate_timestamp` scalars). Both functions therefore still return an empty result for a current-shape work, exactly as their pre-conversion equivalents did against the pre-conversion markdown shape -- the staleness is preserved and recorded, not repaired, per the same disposition as SY-1/SY-2. | `dashboard/reader/parsers.py`:1962 (`parse_quick_check_findings`), `dashboard/reader/parsers.py`:2019 (`parse_delivery_gate`); Node twin `dashboard/server/reader.mjs`:4996, `dashboard/server/reader.mjs`:5079 | Low | S | P3 |
| **SY-4** | Schema gap: an AUTHORED tracking block that cannot be persisted in the current file shape | `aid-describe`'s DESCRIBE-SEED state tracks its own progress (element checklist, coherence-check result, review grade) in a `## Seed Authoring` block it documents appending as raw markdown -- but the per-work state file is now a single pure-YAML document with no separate frontmatter/body split, so that block can no longer be appended into it without corrupting the file's YAML syntax, and no `seed_authoring` key was ever declared in any of the three converted templates (verified: `work-state-template.yml` has no `seed_authoring` key). The owning reference doc already self-flags this as "a schema gap, not a rename target," explicitly out of the scope that converted the three templates. Until a schema decision adds a real key, the mechanical parts of DESCRIBE-SEED (the elicitation loop, the coherence check, the review gate) still run; only the durable, cross-invocation persistence of its resume-point tracking is affected. | `canonical/skills/aid-describe/references/state-describe-seed.md` § STATE.yml Tracking (the accuracy-note callout + the `## Seed Authoring` block it still documents); `canonical/aid/templates/work-state-template.yml` (no `seed_authoring` key) | Medium | S (schema decision) + S (wiring) | P2 |
| **SY-5** | Stale KB facts (a KB doc's own vocabulary section untouched by a corpus-wide format change) | **`domain-glossary.md`'s "STATE.md run-state ledgers" vocabulary section (its own heading: "Vocabulary for the `STATE.md` run-state ledgers") is written entirely against the pre-conversion markdown shape and was not part of the six-KB-doc scope a state-file YAML conversion updated.** It cites the retired `.md` template filenames as its `sources:` (`work-state-template.md`, `delivery-state-template.md`, `task-state-template.md` -- all three renamed to `.yml`), defines its Pipeline State / Task Status / Delivery Gate / Seed Authoring entries in terms of retired markdown headings (`## Pipeline State`, `## Delivery Gate`, `## Seed Authoring`) and a retired section-path (`STATE.md § ### Tasks lifecycle`), and states outright that a task "is tracked by a sibling `STATE.md`" and a delivery's gate is at `deliveries/delivery-NNN/STATE.md` -- all now `STATE.yml`. Same class, smaller extent, in six further docs not in that six-doc scope: `capability-inventory.md` (work `STATE.md`, `STATE.md parser`), `decisions.md` (`STATE.md` in a search-quote and in "creates no work folder, no `STATE.md`"), `authoring-conventions.md` ("Allowed only in `STATE.md` history"), `integration-map.md` ("parses KB + work `STATE.md` files"), `infrastructure.md` (states the dashboard reader "parses `.aid/works/work-NNN/STATE.md`" and that work tracking lives "in `.aid/works/work-NNN-*/STATE.md` files"), and `README.md`:61 (a *different*, pre-existing and unrelated inaccuracy: it names a `## Discovery Domain` STATE.md section that does not exist in `discovery-state-template.md` at all -- not a casualty of this conversion, a separate stale fact). None of these seven docs (`domain-glossary.md` plus the six above) were named in the state-file-conversion documentation task's scope, so a corpus-wide format change left them behind; `.aid/knowledge/kb.html` (`source: generated`) inherits the same staleness by construction and self-heals on its own next regeneration (the KB-summary build) rather than needing a direct edit. | `.aid/knowledge/domain-glossary.md`:111,127,135-136,143,606,624,639-640,672,676-678,680,683-685,688 (the primary offender); `.aid/knowledge/capability-inventory.md`:143,270; `.aid/knowledge/decisions.md`:366,410; `.aid/knowledge/authoring-conventions.md`:141; `.aid/knowledge/integration-map.md`:271; `.aid/knowledge/infrastructure.md`:237-238,246-247; `.aid/knowledge/README.md`:61 | Low | M (`domain-glossary.md`'s vocabulary section is a coordinated rewrite, same shape as `artifact-schemas.md`'s Work/Delivery/Task tables) + S (the other five) | P2 |
| **SY-6** | Same rename, the OTHER half: live skill prose still sends agents to the retired work `STATE.md` | **SY-5 records the Knowledge-Base slice of the `STATE.md` -> `STATE.yml` rename. This is the slice it does not cover: roughly 120 references across ~50 files under `canonical/skills/`, which are LIVE INSTRUCTIONS rather than description.** TWO SLICES, and the second is invisible to any filename-based check: 30 sites name the retired FILE, and 76 name a retired SECTION HEADING without naming any file at all. The sharpest are the heading ones, which cannot exist in a YAML file: `aid-deploy` tells the agent to update `## Deploy State`, `aid-specify` to mark status in `## Features State`, `aid-detail` to write Q&A to `## Cross-phase Q&A`, `aid-define` and `aid-describe` to read state from `.aid/works/{work}/STATE.md`. An agent following any of them writes to a file that no longer exists, or looks for a section that never will. **Why it is separate from SY-5 rather than folded in:** SY-5's entries are prose describing a shape, where being stale misleads a reader; these are imperatives, where being stale misdirects an agent mid-run. Same root cause, different blast radius, and the fix is a coordinated rewrite -- each site needs the correct YAML key (`qa`, `tasks_lifecycle`, `features`, `deploy`), not a filename swap -- with its own review surface. **How it was found, which is the more useful half:** a tree-wide count, after a per-directory gate (AD12) was written for exactly this defect class in `canonical/agents/` and the identical defect sat one directory over, un-gated, because nobody ran the same check there. **Contained meanwhile:** AD13 in `tests/canonical/test-artifact-discipline.sh` freezes the tree-wide count at its measured value, so the residue is bounded and visible and cannot regrow while attention is elsewhere. | `canonical/skills/**` (30 filename sites + 76 section-heading sites); tree-wide ceilings recorded by AD13 (69 / 262 across all tracked files, the rest being the dashboard readers and format converter, which must know the old shape to read it, plus fixtures that must contain it to simulate legacy works) | Medium (an agent following one writes to a non-existent file) | M (coordinated: each site needs its real YAML key, not a rename) | P2 |
| **SY-7** | A generated tour asserting artifact names that no longer exist, and the checker that proves it is not wired in | **`.aid/knowledge/kb.html` names `STATE.md` 16 times and `STATE.yml` never, plus 9 further lines naming the retired per-feature `SPEC.md` and `BLUEPRINT.md`.** It is the KB's visual tour -- the artifact a newcomer or stakeholder reads instead of opening `.aid/knowledge/` -- so it is the surface where a stale name misleads the reader least able to notice. **Found by a new checker that is not yet a gate:** `canonical/aid/scripts/summarize/kb-html-claims-check.sh` derives the CURRENT artifact spelling from the canonical template's existence rather than by counting occurrences, which is the right oracle -- while a rename is in flight the KB legitimately says both names, so a majority test flags the correct one as often as the stale one. Run against the committed `kb.html` it exits 1. Nothing invokes it: no CI job, no skill, no test. **Why it is not fixed here:** `kb.html` is generated by `/aid-summarize`, which carries its own review gates and a mandatory human visual review. Hand-editing generated output to satisfy a checker is the failure the render pipeline exists to prevent, and it would leave the generator still producing the stale text. The fix is one `/aid-summarize` run; the durable fix is that run PLUS wiring the checker into CI, so the tour cannot drift from the KB again. | `.aid/knowledge/kb.html` (25 lines); checker at `canonical/aid/scripts/summarize/kb-html-claims-check.sh`, currently uninvoked | Medium (the tour is what non-technical readers see) | S (`/aid-summarize` re-run) + S (wire the checker) | P2 |

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
| **W1-11** | Cross-work collision (residue) | The skill corpus was renamed and re-shaped, so the collision this row *predicted* has now happened and what remains is residue, not risk. The machine-derived half is **partly discharged**: the repo-wide count guard has been retired, so `tests/canonical/test-doc-counts.sh` now mechanically derives and asserts the counts stated in the public-facing docs, while counts stated in `canonical/` and `.aid/knowledge/` markdown are governed by criterion `G-01` in `authoring-conventions.md` — a declared criterion a reviewer applies, not a guard that runs. The hand-written half is **not** closed, and two survivors are known. The `kb.html` half is **CLOSED**: `/aid-summarize` was re-run to a full regeneration on 2026-08-15 (Summarization History entry #8), taking the file from 21 sections over a 19-doc set to 23 over 21, and the stale corpus figures with it -- `grep -c '75 skills'` and `grep -c '58-row'` are both **0** while `grep -c '34 verb-first'` is still 2, which is the figure that was correct and had to survive. It graded **A+ / A+** (Machine 70/70, Human 30/30) with the V1 visual gate performed by the owner in a real browser, since `validate-visuals.mjs` remains SKIPPED with Playwright absent from the summarize package. The regeneration confirmed the entry's own reasoning: the file was stale rather than unregenerable, GENERATE reads `.aid/knowledge/*.md` directly and writes its own gitignored `.aid/.temp/summarize/` staging tree, and hand-patching was never the remedy. And `W1-2`'s hand-measured per-shape populations are still prose. Neither survivor is machine-guarded, and after the retirement neither is guarded at all: the remaining guard covers only the public-facing docs, and `G-01` reaches only in-scope markdown — so an `.html` file and the maintainer-skill trees are outside both. Re-derive the live figure (`ls -1d canonical/skills/*/`) before trusting any prose enumeration. | `.aid/knowledge/kb.html`; `.aid/knowledge/module-map.md` (see W1-2) | **Medium** | M | **P2** |
| **W1-12** | Intermittent rendering defect | ELK layout is intermittently not applied — diagrams fall back to dagre routing, producing the curved, overlapping edges the owner explicitly rejected at the delivery-003 UI checkpoint. `layout: 'elk'` is present and the loader registers; two hypotheses remain live and untested. **Owner-deferred**, shipped open and disclosed. | `site/astro.config.mjs`:47 + `@mermaid-js/layout-elk` | **Medium** | M | **P2** |
| **W1-13** | Accessibility gap | The node-detail panel is a `div[tabindex="-1"]` with **no `role` and no accessible name** — the accessibility tree shows it as `generic`. Activation moves focus into it, so what a screen reader announces on arrival is not deterministic across NVDA / JAWS / VoiceOver. It does carry an `<h3>` naming the step and a labelled close button, so the content is reachable; the framing is what is missing. Fix is `role="region"` (or `dialog`) plus `aria-labelledby` pointing at the existing `<h3>`. | `site/public/skill-node-panel.mjs` / `site/src/lib/skill-node-panel.ts` | Low | S | P3 |
| **W1-14** | Invalid ARIA | Every decorated node carries `aria-controls="aid-node-panel"` from page load, but the panel is created **lazily on first activation** — so before any node is activated the attribute references an element that is not in the DOM. Confirmed on a fresh load: `document.getElementById('aid-node-panel')` is null while 5 nodes already advertise it. `aria-controls` is specified to reference an existing element. | `site/public/skill-node-panel.mjs` | Low | S | P3 |
| **W1-15** | Unperformed verification | The **screen-reader announcement** check has never been run against a real screen reader. The work-level final gate verified the mechanism (accessibility tree + focus movement) in Chromium, which is not the same thing as the utterance. Needs one NVDA or VoiceOver pass over a skill detail page's chart. Tracked because the check is named in `REQUIREMENTS.md` and in feature-006's blocking default, and a mechanism inspection was substituted for it. | process / manual QA | Low | S | P3 |
| **W4-3** | Test-suite portability (Windows) | **The red count depends on HOW the suites are run, and both figures are real — quoting either one alone has already caused two contradictory measurements to be filed as a disagreement.** Under `tests/run-all.sh` (per-suite `timeout 300`, ~22-way concurrency on this host) **34 fail**. Run **individually with adequate time**, only **23 fail** — the other **9 carry no assertion failure at all** and merely run out of clock under contention. Confirmed by counter-example: `test-frontmatter-lint.sh` is a named member of the environmental red register, yet standalone it is `rc=0`, 57 passed / 0 failed. So 34 measures the *harness budget*, 23 measures *actual portability defects*, and the 9-suite delta is the harness, not the code. A related trap in the register itself: its enumeration is written with quantifiers ("the three `dashboard*` suites") that a glob over-expands — anchored expansion gives **40** files where the literal enumeration sums to 35. Diagnosed 2026-08-04, per suite, with root causes rather than a blanket "environmental" label. Five defect classes: **(A)** POSIX path inside a code string passed to a native tool — 29 sites; note MSYS *does* convert paths in argv, so only in-string paths are affected; **(E)** `chmod`-to-deny is a silent no-op on this filesystem, so negative-permission fixtures never deny — 28 sites, test fixtures only, product has no chmod-deny call; **(F)** fixtures stub only the POSIX `bin/aid` while `os.name == 'nt'` correctly takes the pwsh branch, so `pwsh -File <missing>` exits 64 — ~51 assertions; **(G)** pyenv-win's `python3` shim is a shell script routed through `cmd /C`, which cannot carry an embedded newline, so any multi-line `python3 -c` script is mangled — 47 sites, **the load-bearing one being `find_free_port()` returning an empty string**, which is the first failure in 6 suites including all 31 of `test-aid-remote`'s cascade; **(H)** dependence on local `origin/master` ancestry. **76 of ~80 non-timeout defect sites collapse into two helper functions** — that is the number that makes this tractable. Separately, 9 suites emit **zero** assertion failures and simply exceed the per-suite `timeout 300`; that is a real performance redesign, not a timeout bump (`test-aid-cli.sh` does not finish in 562 s — it forks `basename` once per file across the whole rendered profile tree before its first `echo`), and fixing it **raises** the visible failure count by exposing 19 latent class-E sites. Genuinely CI-only: **2 assertions**, not 2 suites. Sized at **12 distinct pieces: 6 mechanical, 2 design, 1 perf redesign, 3 open investigations** — the largest unknown being ~50 assertions across `test-release` / `test-release-install-e2e` sharing a `release.sh --dry-run` exit-1 root that did not reproduce outside the suite's own `make_clone`. Environment-agnostic is achievable for essentially all 23; it is not achievable cheaply, which is why it is a work of its own and not a delivery bolted onto the skill-corpus change. | `tests/lib/net.sh`:27 and `tests/canonical/**` (per-class site lists to be re-derived at pickup — the 2026-08-04 sweep lived in a scratchpad, deliberately not cited here) | **Medium** | L (phased) | **P2** |
| **W4-5** | Unusable freshness signal (KB data, not code) | The KB freshness reporter can never say `current` or `suspect` for any document, because **not one of the 16 KB docs carries an `approved_at_commit:` key** (`git grep -nE '^approved_at_commit:' -- .aid/knowledge/` returns nothing; positive-controlled against `kb-category:`, which matches 21 lines). Source-drift-versus-approval is the property the reporter computes, so with no approval baseline every doc resolves to `unknown (no approved_at_commit)` and the whole signal is inert. **This is a data gap, not a script defect** — a distinction worth preserving, because the obvious reading blames the script: it does *not* falsely report success, it honestly reports "I cannot tell", and exit 0 means only "the scan completed". Its contract is deliberately reporter-not-oracle (read-only, no file writes, `suspect` a normal verdict), depended on by 16 `FR*` assertions and by `test-conformance-lane-semantics.sh` CL30-CL32, so an assertion must not be bolted into it — and its stdout is load-bearing: `FR14` counts lines matching any of the three verdict words and asserts parity with the TSV row count, so any added summary line naming a verdict breaks the suite. Closing this needs a semantic decision per document (which commit approves it?) back-filled via `migrate-kb-frontmatter.sh`, which is why it is not a mechanical fix. **Separately and independently:** no committed test asserts that the generated `.aid/knowledge/INDEX.md` is reproducible from its source. It currently *is* — verified by rebuilding into scratch and diffing — but a plain diff cannot be the assertion, because exactly three embedded-timestamp lines always differ (the `changelog:` generated date, the `AUTO-GENERATED` comment, and `Generated at:`); masking those three yields a clean diff, and a mask-defeat control (mutate content, then mask) still fails, so the mask does not hide real drift. That assertion belongs in `tests/canonical/test-build-kb-index.sh` with a `coverage-baseline.tsv` row, not in the reporter. | `.aid/knowledge/*.md` frontmatter (16 docs); assertion gap at `tests/canonical/test-build-kb-index.sh` | Low | M | P3 |
| **W5-1** | Incomplete convention rollout | `tests/canonical/select-suites.sh` runs only the suites a change set can affect, but selection is only as narrow as the manifests present: a suite with **no `# COVERS:` header is treated as covering everything and is always selected**. No suite currently carries one, so all **135** suites are selected fail-safe on any change and `--glob` is currently required to keep the output useful. The mechanism is correct but narrow until `COVERS` is promoted across `tests/canonical/`. Deliberately fail-safe in this direction: forgetting a header costs time, never coverage, so an incremental rollout is safe and can be done a family at a time. The one way to lose coverage is a **wrong** entry, so each line is reviewed as a claim about the suite it sits in. **Do not "fix" this by making a missing header mean "covers nothing"** — that inverts the failure mode from wasted time to silently skipped suites. | `tests/canonical/select-suites.sh` + the 135 suites without a `# COVERS:` block | Low | M (phased, per family) | P3 |
| **W5-3** | A frontmatter gate blind to frontmatter that will not parse | **The defect is gone; the gap that hid it is now closed.** Six of 21 KB documents once had frontmatter that was not valid YAML, all from one root cause: a `changelog:` entry is a single-key mapping (`- <date>: <prose>`), and where that prose contained `": "` the parser read a second mapping value and rejected the line. That cause was removed when the change-log apparatus was dropped repo-wide, and **0 of 23 docs are now invalid** — but a defect vanishing because something unrelated removed its cause is not the same as a defect being prevented. **The gap was the more useful half of this row, and it was real until now:** `lint-frontmatter.sh` validates field *presence* and *list-versus-scalar shape* textually, never well-formedness, and its FL19 class soft-skips AID's own KB docs entirely, so the one gate named after frontmatter could not see frontmatter that would not parse. **Closed by** `AD11` in `tests/canonical/test-artifact-discipline.sh`, which runs a real parser over every `.aid/knowledge/*.md` frontmatter block — verified by reintroducing the exact `": "`-in-a-changelog-entry shape and watching it fail. `lint-frontmatter.sh` is unchanged: it does a different job, and widening it would have meant reversing FL19's deliberate soft-skip. | closed: `AD11` | — | — | Done |
| **W5-5** | Silently-failing state write across the whole pipeline | **Every pipeline-phase state write in the methodology fails, and fails invisibly.** `writeback-state.sh` defaults its target to the placeholder `.aid/works/work/STATE.yml` (`:202`, drifted from the `:191` this row originally cited -- the script has since grown comments above the default; the literal string is otherwise unchanged) and expects the caller to export `AID_STATE_FILE`; **14 reference files across seven skills** invoke `writeback-state.sh --pipeline` and **not one** exports it — `aid-define` (1), `aid-deploy` (2), `aid-describe` (2), `aid-detail` (1), `aid-execute` (3), `aid-plan` (1), `aid-specify` (4). Each call exits 1 with `ERROR: ... .aid/works/work/STATE.yml does not exist`, and because the snippet is documented as "silent state-write only — no output, no gate", **nothing surfaces**. `AID_WORK_DIR` does not help: `--pipeline` targets `STATE_FILE`, which honours only `AID_STATE_FILE`, and the script's own comments at `:1329-:1336` record someone hitting that confusion from the other direction. **Observed consequence, which is how it was found:** a work's `STATE.yml` sat at `phase: Specify` / `active_skill: aid-specify` / `updated: 2026-07-31` for days after Specify finished, and had to be corrected by hand. **This defeats the tracking discipline `CLAUDE.md` declares IMPERATIVE** — the phase field is only ever right when a human notices it is wrong. Fix is one line per call site (export `AID_STATE_FILE` from the work id the skill has already resolved), but the *durable* fix is to make the failure loud: a `--pipeline` call whose target does not exist should be a hard error the calling state surfaces, not a swallowed exit 1. Consider also dropping the placeholder default entirely so an unscoped call cannot silently address a non-existent work. **SECOND INSTANCE, same shape but a DIFFERENT env var, found by running `/aid-execute` on a live delivery (2026-08-05).** The *task*-state write path -- `writeback-state.sh --delivery-id DDD --task-id NNN --field State --value V` -- resolves through `WORK_DIR`, which honours `AID_WORK_DIR` (`:195`, `resolve_work_dir` `:227-:230`), **not** `AID_STATE_FILE`. It carries the same placeholder default, so every such call made exactly as documented fails with `ERROR: ... .aid/works/work/deliveries/delivery-001/tasks/task-NNN/STATE.yml does not exist`. **What makes this worse than the `--pipeline` half: these are the writes the skill declares MANDATORY in its loudest terms.** `aid-execute/references/state-execute.md` `:13-:24` gives the "full runnable form" and a four-row transition table, `:313-:317` (PD-2 step 5) gives the orchestrator's own write, and `:337-:394` (PD-2a) instructs every dispatched sub-agent to make the same calls -- and **not one of those sites exports `AID_WORK_DIR`**. So an agent that follows the mandate verbatim writes nothing, and the protocol's own stated failure mode (a task sitting at `Pending` for its whole execution then jumping to `Done`) is produced *by following the instructions*. Fixing the 14 `--pipeline` sites therefore does not close W5-5: the task-state sites need `AID_WORK_DIR` and are a separate sweep. The "make it loud" half of the fix covers both and is the durable one. | `canonical/skills/{aid-define,aid-deploy,aid-describe,aid-detail,aid-execute,aid-plan,aid-specify}/references/*.md` (14 files); `canonical/aid/scripts/execute/writeback-state.sh`:191 | **Medium** | S (call sites) + S (make it loud) | **P2** |
| **W5-6** | Task-template inconsistencies (three, all verified first-hand) | Surfaced while writing a 29-file task set; each was checked against the template bytes rather than taken on report, and re-verified since. **(1) The two task templates disagree on the `Source` arrow.** `canonical/aid/templates/task-detail-template.md:**Source:**` prescribes an ASCII `->`; `canonical/aid/templates/delivery-plans/task-template.md:**Source:**` prescribes U+2192 `→`. A parser keying on either arrow misses half the corpus. (The two once disagreed on the *value* as well — `work-NNN` versus `feature-NNN` — and no longer do; both now say `work-NNN-{name}`.) **(2) The trailing acceptance criterion is self-referential, at five sites:** `- [ ] All section-6 quality gates pass` where section 6 **is** Acceptance Criteria — in `task-detail-template.md`, `delivery-plans/task-template.md`, `delivery-blueprint-template.md`, and twice in `shortcut-engine.md`, each findable by grepping that sentence. It cannot be evaluated without circularity, so in practice it is either ignored or treated as a no-op — worse than absent, because it looks like a gate. **(3) The six-section schema has no field for a wave or phase grouping** and closes with "Six sections … **Nothing else**" (`canonical/aid/templates/delivery-plans/task-template.md:Six sections`), so a work using wave-based gating has nowhere structural to record the wave; it was encoded inside the `Source` line as `-> delivery-001 (Wave N)`, which works but is a convention no template sanctions. | `canonical/aid/templates/task-detail-template.md`; `canonical/aid/templates/delivery-plans/task-template.md`; `canonical/aid/templates/delivery-blueprint-template.md`; `canonical/aid/templates/shortcut-engine.md` | Low | S | P3 |
| **W5-7** | Config resolver returns a COMMENT as the value | `canonical/aid/scripts/config/read-setting.sh` silently resolves a comment into a config value. For a **bare `key:` line whose list continues on the following lines**, a trailing inline comment on that key line is returned *as the value*. Reproduced independently with two side-by-side fixtures: `graph:\n  ignore:   # repo-relative globs excluded from node enumeration\n    - examples/**` makes `--path graph.ignore` print `# repo-relative globs excluded from node enumeration`; move the identical comment down onto the `- examples/**` line and it correctly prints `examples/**`. Cause: in `lookup`/`lookup_list` the whitespace-stripping substitution runs first and greedily consumes the space that the comment-stripping substitution needs as its anchor, so the comment survives and the real value is dropped. **Why this is worse than a parse failure:** it does not error, it returns a plausible-looking string, so a caller cannot distinguish it from a real setting -- and this resolver is the methodology-wide settings reader, not a graph-specific one. **How it was found:** feature-004's SPEC `:1609` shows the `graph.ignore` seed with the comment on exactly that bare `ignore:` line, so writing the SPEC's literal layout triggers it. The comment was moved one line down to route around it and did NOT edit the resolver (out of its declared scope), so nothing shipped is currently broken -- the bug is latent, and the SPEC still shows the triggering layout. No suite covers it: `test-read-setting.sh` passes 19/19. | `canonical/aid/scripts/config/read-setting.sh` (`lookup`, `lookup_list`); trigger layout at feature-004 SPEC `:1609` | **Medium** | S | **P2** |
| **W5-14** | A CSS-block selector matched as an UNANCHORED substring, so one theme's map can be filled from another block entirely | `contrast-check.mjs`'s `blockRegex` (:102-105) builds `new RegExp(escaped + '\s*\{([^}]*)\}', 'gm')` -- **no left anchor**. So the selector `':root'` (:136, the light fallback) also matches **`html:root {`**, and `'html[data-theme="dark"]'` (:137, the CHROME dark map) also matches **`html[data-theme="dark"]:root {`**. Worse, `extractVars` (:117-125) **skips any matched block that declares no `--var` and keeps walking** -- and this file's own comment at :32 records that the chrome carries a `color-scheme`-only dark block with no vars. In a document holding CSS families whose selector names are substrings of each other, the walk can step past the empty dark block and populate `darkVars` from the wrong family; `dark = {...light, ...darkVars}` (:140) then propagates that into every chrome dark pair. **Permanently dormant** as of this tree: the triggering condition was a document containing `html:root {` and `html[data-theme="dark"]:root {` CSS blocks alongside chrome blocks -- a layout produced by an assembly pipeline that has been removed. The bug is still present in `contrast-check.mjs`; the condition that triggers it no longer exists on disk. Record kept so any future CSS assembly that co-locates multiple selector families notices it before shipping. **Fix, if triggered again:** anchor the selector match (require a start-of-line or a `}`/`,`/whitespace boundary before it) and add a PV assertion over any document carrying multiple selector families. | `canonical/aid/scripts/summarize/contrast-check.mjs`:102-105 (unanchored regex), :117-125 (skip-empty-and-continue), :136-137 (the two colliding selectors), :140 (the spread that propagates it), :32 (the chrome's var-less dark block) | **Low** | S (anchor the match) | **P3** |
| **W1-17** | Self-inflicted build break | The AC-1 drift-guard test writes a synthetic orphan page `__test-orphan-skill__.md` **directly into the tracked content collection** (`site/src/content/docs/skills/`) and removes it only in cleanup. An interrupted or killed `npm test` leaves a scratch page in a tracked directory, and the next `npm run build` then fails on the very drift guard the test exercises — a build break caused by the test suite. Every run also momentarily injects a page into the collection a dev server is watching. `discoverSkills()` already accepts a `skillsDir` override and `mkdtempSync` is already imported in the file, so a temp-tree variant needs no new machinery. Raised at delivery-002's gate, left `Pending` there, and carried here at the final gate because it is the one of that gate's unclosed rows whose consequences outlive the work folder. | `site/scripts/__tests__/gen-skills.test.mjs`:539-545, 572-573 | Low | S | P3 |
| **W7-1** | Untested-by-construction CI lane (a guarantee with a hole in the lane developers feel) | `test.yml`'s **`canonical-tests`** job — the lane that runs `tests/run-all.sh` on **every pull request** — carries a `setup-node` step but **no `setup-python` step at all**, so it executes every Python suite it drives against whatever interpreter the `ubuntu-24.04` runner image happens to ship. The two `setup-python` steps in that file (`:50` in `render-drift`, `:118` in `generator-selftests`) belong to other jobs and do not reach it. **Two consequences.** (1) The dashboard reader and server suites — 794 Python tests plus the parity suites — are proven on a *declared* interpreter only at tag time via `release.yml`'s `gate`, never on a pull request. (2) **Any check that verifies pins is structurally blind to this**, because a check reading `python-version:` scalars cannot see a job that declares none; a future anti-drift guard would therefore ship green and partial on day one. Fix is one SHA-pinned `setup-python` step in `canonical-tests`, matching the exact form the other two jobs already use (`.github/dependabot.yml` states the SHA-pinning policy). **Note the interaction with M5:** that entry records the declared floor being untested, and this entry is *why* the PR lane cannot demonstrate any floor at all; resolving M5 by dropping the PyPI channel would remove M5's subject but leave this lane still unpinned, since the dashboard reader and server remain Python for as long as they remain Python. | `.github/workflows/test.yml`:65 (`canonical-tests:`), `:70` (`setup-node`, the only runtime pin in the job), `:50` and `:118` (the two `setup-python` steps, both in other jobs) | **Medium** (a PR lane outside the version guarantee; masks interpreter-specific regressions until tag time) | XS (one step) | **P2** |
| **W7-2** | Migration blocked by a false premise about which zone a section belongs to | **CLOSED.** The `STATE.md` -> `STATE.yml` converter refused every work that had been through `/aid-define`, and the remedy its own error named could not run. `_aid_sc_guard_derived_table` treated any real table row in a DERIVED-zone section as proof that the work predated the per-unit hierarchy, but `## Features State` is not DERIVED -- `/aid-define` creates a row per feature and `/aid-specify` updates it -- so a work that had merely completed decomposition was misdiagnosed and refused, while the named remedy (`migrate-work-hierarchy`) exits 3 on any work with no `tasks/`, which is exactly that population. **Closed by declaring the key rather than by exempting the section**, because exempting it would have made conversion silently DROP the feature rows: `features[]` is now an AUTHORED key in `work-state-template.yml` (see `artifact-schemas.md`), the converter emits it, and its row count is checked by the round-trip verifier. **Four further defects in the same code path were found once conversion could proceed past the guard, every one of them previously unreachable and every one silent** — which is the more general lesson here: a guard that refuses early hides the bugs behind it, so the guard's own removal is what surfaces them. (1) The emitters merged **every** table in a section's range, so a `## Interview State` section's Review History rows and its header/separator lines landed in `interview.sections`; fixed by locating tables from their separator row and selecting one by header cell. (2) A fixed-field `read` glued a wider-than-expected row's remaining cells into the last variable **with the raw `\x1f` field separator**, making the whole document unparseable; fixed by `_aid_sc_row_split`, which pads, folds extra cells in, and cannot leak the separator. (3) `_aid_sc_qa_entries` read only the `State` bullet label, but every pre-conversion work writes `Status` — the naming contract renamed the templates, not the works already written against them — so **28 of 28 Q&A entries converted with an empty `state`**, emptying the one field that says whether a question is still open; fixed by falling back to `Status`. (4) An inline HTML comment annotating why a state was last changed rode along inside the enum value, so `Closed <!-- ... -->` compared equal to nothing; the annotation now moves to `answer` and the enum stays clean. (5) **Fixing (1) turned a mis-filing into a deletion, which is worse, and that is worth recording as its own step rather than folded into (1):** the interview's Review History table shares the `## Interview State` range, so selecting `interview.sections` by header correctly stopped its rows being mis-filed as sections — and then dropped them, 13 rows of a real work's interview record. A table the schema does not name is still data, so `review_history[]` is now a declared AUTHORED key too, closing the second of the two gaps those skill accuracy notes had named. Regression-gated by `G15E-01`..`G15E-20` and `WS21`, **each fix mutation-tested** — reverting any one of them turns its own assertions red. | closed: `bin/aid` (`_aid_sc_emit_features`, `_aid_sc_table_rows`, `_aid_sc_row_cells`, `_aid_sc_row_split`, `_aid_sc_interview_header`, `_aid_sc_qa_entries`); `canonical/aid/templates/work-state-template.yml` (`features:`); `tests/canonical/test-aid-migrate.sh` Gate 15e; `tests/canonical/test-work-state-template.sh` WS21 | — | — | Done |
| **W7-3** | The state-format conversion is lossy on everything the YAML schema does not name, and silent about it | **A `STATE.md` -> `STATE.yml` conversion discards every block the key set does not claim, reports success, and offers no way back.** Measured on a real work: **110,852 bytes in, 64,138 out — 42% of the document gone**, and what went is not filler. Three blocks of live content had no key: the `### Decisions carried from the originating interview` table (**14 architectural decisions, each with the alternative it rejected and why** — cited by requirement and criterion reasoning throughout that work), the `### Cross-Reference` narrative (grade, cycle count, grade trajectory, and the dated coverage note that says which parts of an earlier proof no longer hold), and a ~40-line scope-reset blockquote under `## Interview State` recording a runtime decision and its three cascading consequences. **This is structural, not a bug in one emitter.** Every emitter maps a table or a bullet list to a declared key; free prose and any table the schema does not name have nowhere to go, so a work whose state file carried narrative loses that narrative. Nothing warns: the subsystem is WARN-not-fail and a clean run prints `OK: ... converted`. **Why "it is in git" is not the answer.** The converter's runbook names VCS as the only path back (no reverse converter exists, deliberately), which is fine for an *archive* and wrong for *state an agent reads*: after conversion the live artifact no longer contains the decision registry that its own requirements argue from, and no reader is told to go looking. It is also the same reasoning the tracking-discipline rule rejects elsewhere — untracked work is incomplete work. **Three ways out, and choosing between them is a schema decision rather than a fix:** declare keys for the remaining blocks (`decisions[]`, and a free-prose key per section) and accept a wider schema; relocate the content to where it now belongs (`decisions.md` in the Knowledge Base for the D-rows, `REQUIREMENTS.md` for interview rationale) as a per-work migration step; or make the converter **refuse** a file whose content it cannot fully place, which turns silent loss into an actionable failure and is the minimum bar whichever of the other two is chosen. **Found by** converting a 112 KB work state file after `W7-2` unblocked it, then diffing the byte counts rather than trusting the `OK` line — the conversion that produced it is deliberately **not committed**. | `bin/aid` § `STATE.md -> STATE.yml FORMAT-4 CONVERSION` (`_aid_sc_convert_work_body` and the emitters it dispatches; the runbook's rollback note); `canonical/aid/templates/work-state-template.yml` (the key set) | **High** (a conversion silently discards decision rationale and reports success; irreversible in-place) | M (schema decision) + S (make it refuse) | **P1** |
| **W5-22** | Adopter-facing automation gap | **AID ships no adopter-facing skill that drains the committed backlog into the release ledger.** At tag time every item in `backlog.md` § `## Next Release` must move into a new version section of `release-tracking.md` and be deleted from `backlog.md` in the same pass. This repository performs that drain with `release-aid`, which is **repo-local**: it lives only under `.claude/skills/release-aid/`, is absent from `canonical/skills/`, and is therefore never rendered to a profile and never installed into an adopter's project. **Risk if left:** an adopter's item flow stalls at `backlog.md` — items accumulate in a section whose entire purpose is to be drained, with nothing shipped to drain it, so backlog and release ledger drift apart at every tag. The interim answer is documentation rather than automation, and it is deliberate: the `### backlog.md` block of `document-expectations.md` states the drain as a manual step, on a canonical surface that reaches all five profiles. Closing this means giving the drain an executable canonical home — a skill — which is a work of its own and was ruled out of scope rather than overlooked. One adjacent inaccuracy a fix should sweep up with it: `canonical/skills/aid-create-backlog/SKILL.md`'s `## Gotchas` text names `release-aid` as the drainer, inside a canonical file adopters receive, where no such skill exists for them. | `canonical/skills/aid-discover/references/document-expectations.md` § `### backlog.md` (the manual-step paragraph); no counterpart anywhere under `canonical/skills/` | Low | M | P3 |
| **W5-23** | Incomplete registration surface | **36 of the 61 documents the domain matrix names have no `### <filename>` block in `document-expectations.md`** — computed, not sampled: the eight domain tables of `domain-doc-matrix.md` name 61 distinct filenames and the expectations file carries 27 `### <filename>` blocks, so the join the matrix schema declares resolves to nothing for roughly two thirds of the documents it indexes. **Pre-existing, and neither created nor widened by the three blocks added alongside this row** — those three documents gained a matrix row and a block in the same change, so the uncovered count is what it was. **Risk if left:** a reviewer working any of the 36 gets no per-document expectations at all, and the matrix's declared join target stays incomplete for the majority of its own entries. **Why nothing breaks today:** a document's MUST-floor is its spine-dimension depth standard (the `### C<N>` blocks), and a `### <filename>` block is an additive refinement layered on top of that floor, never a replacement — so every matrix document still has a floor to be reviewed against, which is why this is a gap rather than an outage. Closing it is 36 authored blocks, each owing the same four-part anatomy (question / investigate / operational open question / red flags), which is what sizes it as a work rather than a chore. | `canonical/skills/aid-discover/references/document-expectations.md` (its `### <filename>` block set); the domain tables of `canonical/aid/templates/kb-authoring/domain-doc-matrix.md` | Low | M | P3 |

### Skill Explorer — open known issues

The Skill Explorer effort registered 22 known issues. **Twelve are closed** — KI-003, 005, 006,
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

### [MEDIUM] L5 -- The review loop re-reads everything, and re-judges what it could run

**One problem, two causes, two remedies that only work well together.** Both remedies were
proposed separately; they are recorded here as one item because each fixes the other's weakness.

#### The cost, measured

Modelled against this project's observed averages for a full-path work (3-4 features, 4-5
deliveries, 16-25 tasks, 5-7 review cycles per gate), review gates account for roughly **61-65%
of total work cost** — about **4.7-6.7x** the cost of authoring the documents being reviewed. The
worst single line is the per-feature specify gate, because three multipliers stack: per feature x
per cycle x whole documents. A requirements document of ~88 KB gets re-read 15 to 28 times inside
the specify gates alone.

Independently observed on a later work: re-reading the same feature specs across gate cycles cost
roughly **1.9M input tokens**, against ~452k output tokens to author all thirteen specs once — the
review loop costing about **4x the authoring**. Of 25 gate cycles recorded on that work, **four
moved the grade zero**.

#### Remedy 1 -- scope the cycle N≥2 hunt

Cycle 1 keeps reading the whole artifact. **Cycles 2+ verify the existing ledger in full, but hunt
for NEW findings only in what the previous FIX changed.** One final full pass runs before approval
as the backstop.

The mechanism is a single clause in `reviewer-ledger-schema.md`'s cycle N≥2 workflow. Everything
before its last sentence is already targeted and cheap — verify each `Pending` row on disk, promote
to `Fixed`, demote a regressed `Fixed` to `Recurred`. It is the last sentence, *"Append new rows as
`Pending` for newly-found issues"*, that forces the full re-read, because finding new issues means
re-scanning everything. Split that clause: ledger verification stays full, new-finding discovery
becomes scoped.

**Why this needs declared criteria to be safe.** Scoping the hunt invites one objection: what stops
a scoped cycle missing something? Without declared criteria there is no principled answer — it is a
judgment call. With them, a scoped cycle becomes a *bounded check*: "verify all resolved criteria
against the changed sections", and the criterion `id`s make coverage provable rather than asserted.

**Three guards it must carry:**

1. **A fix in one section breaks another.** The scoped surface must include the sections that
   *reference* the changed ones — mechanical cross-reference lookup, not model judgment.
2. **Cross-document contradictions.** Real precedent exists (a vocabulary file/format contradiction
   spanning three features, caught as `[CRITICAL]`). Keep that pass, but run it **once per phase**
   rather than once per cycle per feature; it was never a per-cycle check.
3. **A missed finding survives.** `Recurred` already exists in the Status enum for exactly this, and
   the final full pass is the backstop.

**Related, same edit sites:** stop passing a whole requirements document to a per-feature specify
gate; pass the slice that feature traces to. On its own that saves an estimated 300-600k tokens per
work.

**Edit sites:** the cycle N≥2 clause in `reviewer-ledger-schema.md`; `reviewer-dispatch.md`'s
`ARTIFACTS UNDER REVIEW` (carry the changed-section set on cycles 2+) and `RUBRIC` (resolve criteria
against the scoped surface); the six `reviewer-brief.md` files.

#### Remedy 2 -- an optional `oracle:` on a criterion

Every criterion is verified by a reviewer *reading* it. For a genuinely semantic criterion that is
unavoidable. For a mechanically decidable one it is both waste and a reliability problem: `G-07`
("every in-scope markdown file resolves to exactly one type in the registry") is re-derived by hand
each cycle — read the registry, read the corpus definition, enumerate files, apply each selector —
which is expensive and inconsistent between cycles.

Add **one optional key** to a criterion entry, carrying an executable check that an agent generates
once, in the project's own terms:

```yaml
review-criteria:
  - id: G-07
    criterion: "Every in-scope markdown file resolves to exactly one type in the registry."
    severity: HIGH
    why: "A file matching two rows or none has no resolvable criteria set."
    oracle: scripts/checks/g07-selector-partition.sh   # generated once, by an agent
```

A criterion with an oracle is re-decided by *running* it: cheap, deterministic, and identical on
every cycle. A criterion without one behaves exactly as it does today, which is why the key is
optional and its absence is not a defect.

#### Why they are one item

Remedy 2 removes remedy 1's sharpest objection. A scoped cycle is only sound for criteria that can
be *evaluated* against a subset — and evaluation scope varies per criterion: `G-01` (cosmetic
counts) fires on a local occurrence, `KB-02` (one concern per doc) needs the whole file, and `G-07`
needs the whole corpus. A criterion with an oracle sidesteps that entirely: it is re-run at any
scope for negligible cost, so its evaluation scope stops mattering. The worked example above is
`G-07` — precisely the criterion that is the worst case for scoping.

Sequencing remedy 2 before or alongside remedy 1 therefore *removes* the correctness objection
instead of guarding around it.

#### Prerequisites, already satisfied

Both remedies extend the declared-criteria mechanism rather than revising it, because two
compatibility properties were settled deliberately when that mechanism was built:

- **Resolution is scope-free.** A file's resolved criteria list depends only on its path and
  frontmatter, never on its content, so the list for a section *is* the list for the file. Remedy 1
  needs no change to resolution.
- **A criterion entry tolerates unknown keys** (`frontmatter-schema.md § Parsing rules`). Remedy 2's
  `oracle:` is therefore a pure addition — a new key and a new reader — not a migration across every
  criterion already declared.

### [HIGH] L4 -- No measure of test-suite effectiveness

**Type:** Test-effectiveness gap / methodology

**Description:** AID has ~135 canonical suites but **no signal for whether they are
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
The ~75 prompt-driven skills are **out of scope** for these techniques (there is no
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
