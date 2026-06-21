# Lockstep Dependents & CI Closeout

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-20 | Feature identified from REQUIREMENTS.md §5 FR8, §4 In-Scope 5, §7 C7, §9 AC3/AC4 | /aid-interview |
| 2026-06-20 | Cross-ref Q3: added scope to revise content-isolation cornerstone R6 (`content-isolation.md`) for Codex `.codex/{agents,skills,aid}` (FR2) | /aid-interview |
| 2026-06-20 | All-tools research: KB lockstep also retires the rules-mechanism terms (`rules_frontmatter`, `antigravity-rule` format, `.cursor/rules`/`.agent/rules` references) in domain-glossary/integration-map, since FR3 deletes the mechanism | /aid-interview |
| 2026-06-20 | Technical Specification drafted (aid-specify); residual-vs-owned delineation table (no gap/overlap); 5 decisions confirmed — OQ1 004 owns `release.sh` codex roots, OQ4 new `host-tool-capabilities.md` KB doc, OQ2 inline-semantics + housekeep-numerics, OQ3 no skill/agent count change, OQ5 two-part AC4 (structural suite + manual behavioral) | /aid-specify |
| 2026-06-20 | A+ review (D+ → fix): corrected architecture.md renderer-inventory cite (:131→:248,251); fixed docs.yml-not-a-PR-gate factual error (AC3 docs-build is post-merge); dropped "pending OQ1" leftovers; closed 4 OQ confirm-trailers; added install.md :769 + aid-methodology :825 stale-layout cites; sync-docs :31-72; docs.yml deploy :75 | /aid-specify REVIEW |
| 2026-06-20 | Downstream alignment to sibling corrections (intent-fidelity review correction): AC4 behavioral half widened to the work's 3-tool scenario (Cursor + Claude Code + Codex) to match AC4a, with Copilot CLI + Antigravity named as asserted-via-Finding-D1-not-exercised (structural `test-multitool-isolation.sh` half unchanged); delineation table + content-isolation R6 implementation-note updated to FR5 Option (c) MINIMAL (`rewrite_install_paths` reduced to one-line `{root}`-prefix, not deleted; no `{AID_ROOT}` placeholder); capability-study handoff references updated to the single-doc shape (no separate `format-decision.md`) | intent-fidelity review |

## Source

- REQUIREMENTS.md §5 (FR8)
- REQUIREMENTS.md §4 (In Scope 5)
- REQUIREMENTS.md §7 (C7)
- REQUIREMENTS.md §9 (AC3, AC4)
- REQUIREMENTS.md §7 (C1) / §8 (D1) — content-isolation cornerstone R6 revision for Codex (FR2 / cross-ref Q3)

## Description

Bring the residual cross-cutting dependents into lockstep with the new layout — the ones
that are not naturally owned by features 001–003. These are `release.sh` tarball roots,
the `docs/*` files and their synced `site/*` copies, the `.aid/knowledge/*` documents
(including the deliberate revision of the content-isolation cornerstone doc —
`content-isolation.md` rule **R6** — to reflect the Codex `.codex/{agents,skills,aid}`
unification per FR2 / cross-ref Q3), and the profile READMEs. This is a thin closeout,
not a catch-all: per-feature dependent
updates (for example, a test or install change caused by the generator collapse or the
update logic) belong to the feature that caused them, not here.

Once the residual dependents are consistent, this feature runs the final acceptance gate:
all CI green and a real multi-tool repo verified end to end. The work lands via PR from a
delivery branch under the PR-protected master.

## User Stories

- As an AID maintainer, I want every residual dependent — release packaging, docs and their synced site copies, the knowledge base, and profile READMEs — brought into lockstep with the new layout, so that no shipped artifact references the retired layout.
- As an AID adopter running several tools in one repo, I want a real multi-tool repo (claude-code + cursor + codex) verified so that each tool uses only its own tree with no cross-contamination, so that I can trust multi-tool coexistence in production.
- As an AID maintainer, I want a final all-green CI gate across render-drift, the full suite, generator self-tests, installers on Windows and Linux, the docs build, and version-sync before the work ships, so that the simplification lands without regressions.

## Priority

Must

## Acceptance Criteria

- [ ] Given all residual dependents are updated, when CI runs, then it is fully green: render-drift, `tests/run-all.sh` (53+ suites), generator self-tests, installer (Windows + Linux), the docs (Astro) build, and version-sync all pass. (AC3)
- [ ] Given a real multi-tool repo with claude-code + cursor + codex installed, when each tool is exercised, then each uses its own tree with no cross-tree contamination. (AC4)

---

## Technical Specification

> **Feature character.** This is the **thin integrating closeout** of work-005 — the
> *last* feature. It owns only the **residual cross-cutting dependents** that no single
> sibling naturally owns, the **content-isolation.md R6 revision** (cross-ref Q3), the
> **capability-study KB promotion** (feature-001 ship-time handoff), and the **final
> acceptance gate** (AC3 all-green CI + AC4 multi-tool no-contamination). It produces
> **no generator code, no CLI/install code, and no `profiles/*` tree edits** — those are
> features 002 and 003. It runs **after** 001/002/003 have landed, against the settled
> layout. Because the deliverable is offline maintainer + docs + KB work plus a CI gate,
> most application-oriented sections are honestly **N/A**.

> **No double-ownership / no gap.** The Residual-vs-Owned delineation table (under Layers &
> Components) is the load-bearing artifact: every dependent named in REQUIREMENTS §4
> In-Scope-5 / FR8 is assigned to exactly one feature. Where a sibling's spec already
> claims a file (e.g. feature-002 owns `canonical/EMISSION-MANIFEST.md` and all
> `profiles/*`; feature-003 owns `lib/*` install-core + `tests/canonical/test-aid-migrate.sh`),
> this feature does **not** touch it.

### Section Applicability

| Section | Status | Rationale |
|---------|--------|-----------|
| **Layers & Components** | **Activated** | The substantive section: the **residual dependent file inventory** (release.sh codex roots, `docs/*` + synced `site/*`, `CONTRIBUTING.md`, profile READMEs, the KB term-retirement set + content-isolation.md R6 + the capability-study promotion + INDEX/README regen) **plus the residual-vs-owned delineation table** proving no gap/overlap with 001/002/003. |
| **Feature Flow** | **Activated** | Not request→service→repo. The closeout flow: **(siblings land) → lockstep-update residuals → regen INDEX/README → run the final acceptance gate (AC3 + AC4) → PR to PR-protected master**. |
| **Telemetry & Tracking** | **Activated (light)** | The "telemetry" here is the **CI gate surface** — the exact green-CI checklist (the 4 `test.yml` jobs post-collapse, `docs.yml` Astro build, `release.yml`/version-sync) that AC3 asserts, plus the manual AC4 multi-tool acceptance procedure. |
| **Migration Plan** | **Activated (doc-sync only)** | No data/install migration (that is feature-003). The only "migration" is **doc/site/KB content sync** to the new layout + the one-time `docs/* → site/*` re-sync via `sync-docs.mjs`. |
| Data Model · API Contracts · UI Specs · Events & Messaging · DDD/CQRS/State Machines · BDD · Security · Cache/Search/Batch/Mobile/Cloud/Hardware/Recovery · AI Enhancements · External Integrations | **N/A** | This feature adds no schema, no CLI/API surface, no UI, no events, no auth, no runtime app/AI surface. It edits prose dependents and runs a gate. The `aid` CLI contract is feature-003; the renderer/agent-dispatch model is feature-001/002. |

---

### Layers & Components — The Residual Dependent Inventory + Delineation

#### A. Residual-vs-Owned delineation table (the no-gap/no-overlap proof)

Every dependent surface named in REQUIREMENTS §4 In-Scope-5 + FR8, mapped to its single
owning feature. **feature-004 owns only the rows marked "004 (residual)".**

| Dependent surface | Owner | Why / boundary |
|-------------------|-------|----------------|
| `canonical/` content reshape (`canonical/aid/` nest; FR5 keeps the minimal `{root}`-prefix substitution — no `{AID_ROOT}` placeholder, no canonical content rewrite), `canonical/rules/` deletion, `[extras]` mechanism | **002** | Generator collapse (FR1/FR3/FR5/FR6). |
| Generator scripts `.claude/skills/generate-profile/scripts/*` (13→4), dead-test deletion (`test_copilot_emitter.py`, `test_antigravity_emitter.py`) + **their CI de-wire** (`test.yml:97-98`, `release.yml:166-167`) | **002** | Feature-002 §Layers explicitly owns the CI de-wiring of the deleted self-tests. |
| `profiles/*` rendered trees (Codex unify, rules removal, dogfood `.claude/` re-render) | **002** | Output-tree reshape. |
| `canonical/EMISSION-MANIFEST.md` (drop `rules` row, collapse Codex split column) | **002** | Feature-002 §Data Model explicitly updates it. |
| New `tests/canonical/test-dogfood-byte-identity.sh` (§7a/C2 guard) | **002** | Feature-002 §"§7a/C2 Guard" owns it. |
| `lib/aid-install-core.sh` + `lib/AidInstallCore.psm1` + vendored copies; `bin/aid` + `bin/aid.ps1` | **003** | Install/CLI twins (FR7/FR10/FR11). |
| Migration/installer tests `tests/canonical/test-aid-migrate.sh`, `tests/windows/Test-AidInstaller.ps1` | **003** | Feature-003 §Migration Plan owns the old-layout fixtures. |
| The FR4a **capability-study** (with its embedded decision section) authoring (in `.aid/work-005-.../research/capability-study.md`) | **001** | Research/decision feature; authored work-local (the separate `format-decision.md` was folded into the one study doc per the intent-review correction). |
| **`release.sh` codex tarball roots** (`build_tarball "codex" … ".agents" ".codex" …` → `".codex"`) + the root-map comment block (`release.sh:189-194, 281`) | **004 (residual)** | **GAP:** feature-002 reshapes `profiles/codex/` but its spec scopes to *committed trees + generator*, never `release.sh`; feature-003 scopes to `lib/`+`bin/`. Neither claims the packaging script. See §B.1 + Open Question 1. |
| **`docs/*.md`** layout references (`install.md`, `repository-structure.md`, `faq.md`, `aid-methodology.md`, `glossary.md`) | **004 (residual)** | User-facing docs; not owned by any sibling. |
| **`site/src/content/docs/*`** synced + hand-authored copies (re-sync 4 docs via `sync-docs.mjs`; hand-edit `guides/installation.mdx` + `reference/cli.mdx`) | **004 (residual)** | Site is the docs-build input (AC3 Astro build). |
| **`CONTRIBUTING.md`** profile-tree references (codex split lines, generated-tree list) | **004 (residual)** | Contributor doc; not owned by a sibling. |
| **`profiles/{cursor,codex}/README.md`** (+ verify `claude-code/README.md`) | **004 (residual)** | Profile READMEs are explicitly named in In-Scope-5. *(NB: feature-002 re-renders profile *trees*; the per-profile README.md is hand-maintained and excluded from the tarball — `release.sh` build_tarball excludes README.md — so it is a residual doc edit, not a render output.)* |
| **`.aid/knowledge/*`** term-retirement + R6 revision + capability-study promotion + INDEX/README regen | **004 (residual)** | The KB lockstep is feature-004's by REQUIREMENTS FR2/FR8/cross-ref Q3. See §B.3. |

> **Confirmed (2026-06-20) — Open Question 1 (release.sh ownership) → feature-004 owns it:** this spec **claims
> `release.sh`'s codex roots as a feature-004 residual** because neither sibling spec names
> it. If the team prefers it land with feature-002 (the feature that reshapes `profiles/codex/`
> and would notice the tarball break first), reassign that one row to 002. Either way it must
> have **exactly one** owner — flagging it here prevents the gap.

#### B. The residual edits in detail

##### B.1 — `release.sh` codex tarball roots (residual — feature-004 owns it; OQ1 confirmed)

`release.sh:281` packages the codex tarball from two roots:
```
build_tarball "codex" "profiles/codex" ".agents" ".codex" "AGENTS.md"
```
After FR2 unifies Codex under `.codex/{agents,skills,aid}` and retires `.agents/`, this
becomes a single root:
```
build_tarball "codex" "profiles/codex" ".codex" "AGENTS.md"
```
The root-map comment block (`release.sh:189-194`) and the codex comment at `:280` update
to drop `.agents/`. `build_tarball`'s "Expected install root not found" guard (`:261`) then
correctly fails the release if `profiles/codex/.agents/` were to reappear — a free
regression catch. **No other tool's roots change** (claude-code `.claude`, cursor `.cursor`,
copilot-cli `.github`, antigravity `.agent` are unchanged — rules-folder removal is *inside*
those roots, handled by the omitted-from-manifest mechanism, not the tarball root list).
This is the *only* `release.sh` change; the CLI bundle, SHA256SUMS, and the 5-tool loop shape
are untouched.

##### B.2 — Docs + synced site copies (residual)

The retired-layout references, by file (all narrow, layout-only edits):

| File | What to change | Sync path |
|------|----------------|-----------|
| `docs/install.md` (`:35,418-423,769`) | `.codex/` + `.agents/` install desc → single `.codex/{agents,skills,aid}`; drop the "`.agents/` alternate path" bullets | not in `sync-docs` manifest — standalone (verify no site consumer) |
| `docs/repository-structure.md` (`:29,86`) | codex row `.codex/ + .agents/` → `.codex/`; tree view | **synced** → `reference/repository-structure.md` |
| `docs/faq.md` (`:32`) | "installs to `.codex/agents/` + `.agents/`" → `.codex/` | **synced** → `concepts/faq.md` |
| `docs/aid-methodology.md` (`:825,826,835,838,860`) | retire the **copilot-agent** + **antigravity-rule** format bullets; the per-tool format table (codex split, the 4-format column) → uniform markdown; the `{.claude/ \| .codex/+.agents/ \| …}` layout line | **synced** → `concepts/methodology.md` |
| `docs/glossary.md` (`:109`) | codex `.codex/agents/` + `.agents/` → `.codex/` | **synced** → `reference/glossary.md` |
| `site/src/content/docs/guides/installation.mdx` (`:19,205-206`) | hand-authored; `.codex/` + `.agents/` install desc → `.codex/` | **hand-edit** (not synced from docs/) |
| `site/src/content/docs/reference/cli.mdx` | hand-authored; verify no `.agents`/codex-split mention survives | **hand-edit** |

**Sync mechanism:** the four mapped docs (`aid-methodology`, `faq`, `repository-structure`,
`glossary`) propagate to `site/src/content/docs/` via `node site/scripts/sync-docs.mjs`
(MANIFEST table, `sync-docs.mjs:31-72`). This feature edits the `docs/*` source, then **runs
`sync-docs.mjs` and commits the regenerated site copies** so the Astro build (AC3) sees the
new content. `installation.mdx` and `cli.mdx` are **not** synced (not in the manifest) and are
edited directly. `gen-reference.mjs`-generated pages (`skills.md`/`agents.md`/`kb.md`/
`settings.md`) carry **no layout references** and need no edit here (skill/agent *counts* are
unchanged by work-005 — no skills/agents added or removed — so no count-drift housekeep; see
Open Question 3).

##### B.3 — KB lockstep (residual): term-retirement + R6 + capability-study promotion + regen

**(i) content-isolation.md R6 revision (cross-ref Q3 — the concrete edit).** Three spots:

- `content-isolation.md:60` (Rule 1 nest table, codex row):
  `| codex | `.agents/` | `.agents/aid/{scripts,templates,recipes}` (NOT under `.codex/`) |`
  → `| codex | `.codex/` | `.codex/aid/{scripts,templates,recipes}` |`
- `content-isolation.md:71-72` (the **R6** "Codex split" scope note):
  *"Codex split (R6): the nest applies to `.agents/`; `.codex/` ships only `agents/`…"*
  → rewritten as **R6 (revised, work-005 FR2):** *"Codex is unified under `.codex/`; the
  `aid/` nest applies to `.codex/aid/`, and agents/skills live at `.codex/{agents,skills}`.
  The former `.agents/` split (the original R6) is **retired** by work-005 FR2 — recorded
  here as a deliberate cornerstone evolution, not a silent drift."*
- `content-isolation.md:75-78` (implementation note citing `render_lib.py rewrite_install_paths`
  + the three dst builders) → updated to the feature-002 reality: the nest is now structural
  (`canonical/aid/ → {root}/aid/` copy), `rewrite_install_paths` reduced to the minimal
  one-line `{root}`-prefix substitution (FR5 Option (c); multi-dir branching removed). Also the `:172`
  scoping-question example mentioning `.codex/aid/` is left correct (it now *is* the path).

The R6 edit is recorded in `content-isolation.md`'s changelog with the cross-ref Q3 paper
trail, satisfying C1/D1's "the cornerstone evolves on purpose with a paper trail, not silently".

**(ii) domain-glossary.md term-retirement.** The all-tools research deletes the rules-mechanism
+ multi-format machinery, so these terms are retired/revised (`domain-glossary.md`):

| Term (line) | Action |
|-------------|--------|
| **Split-root layout (Codex)** (`:294`) | **Retire** — replace with a one-line "retired (work-005 FR2): Codex unified under `.codex/`" tombstone, or delete the row + note in changelog. |
| **Agent format** (`:298`) | **Revise** — `markdown \| toml \| copilot-agent \| antigravity-rule` → uniform **markdown** (with a `toml` Codex exception note iff E-CODEX-1 retains it per feature-001/002). |
| **`copilot-agent` format** (`:300`) | **Retire** (branch deleted, FR3/FR4). |
| **`antigravity-rule` format** (`:301`) | **Retire** (branch deleted). |
| **`rules_frontmatter` trigger-dialect** (`:303`) | **Retire** (`[extras]` mechanism deleted, FR3). |
| **Install Tree** (`:286`) | **Revise** — codex sub-path `profiles/codex/{.codex,.agents}/` → `profiles/codex/.codex/`. |

**(iii) integration-map.md + pipeline-contracts.md + architecture.md** (the renderer-contract
prose): retire the "**4 agent formats** (`markdown/toml/copilot-agent/antigravity-rule`)" claim
(`pipeline-contracts.md:20,702`; `architecture.md:23`); update the Codex-split skill-path
prose (`pipeline-contracts.md:40-41,555`); update `architecture.md`'s `profiles/` tree view
(`:79,84-93` — drop `rules/`, the split `agents_root/assets_root`, the `codex/.agents/` line,
the antigravity `.agent/rules/`), the per-asset-renderer inventory + the 4 agent formats
(`architecture.md:248`) and the emitter self-tests (`:251`) → the 4-script set; `integration-map.md`'s renderer LOC/file list (`:194-199`).
*(module-map.md "13 renderer Python files" and test-landscape's "49 suites" counts also drift
— but those track generator/test inventory that **feature-002 changes**; see Open Question 2
on whether the count reconciliation is inline here or deferred to `/aid-housekeep`.)*

**(iv) Capability-study KB promotion (feature-001 ship-time handoff).** feature-001 authors
the study work-local at `.aid/work-005-.../research/capability-study.md` (a single doc carrying
both the per-tool table and the decision section — the separate `format-decision.md` was folded
in per the intent-review correction) and explicitly **defers the durable KB home to feature-004**. This feature promotes the
**verified** study to a durable KB doc at ship-time. See §B.4 for the home choice.

**(v) INDEX.md + README.md regen (lockstep consequence).** After all KB edits — and especially
**if** a new KB doc is added (§B.4) — regenerate the index, **not by hand**:
```
bash canonical/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md
```
(the `kb-hygiene` CI job at `test.yml:118-124` fails on a stale INDEX). `README.md`
(`kb-category: meta` completeness tracker) is updated to reflect the new doc count + any
retired terms. `release-tracking.md` Unreleased section gets the work-005 `[CHANGE]` entries
(per the release-tracking KB convention), then INDEX regenerated again if needed.

##### B.4 — Capability-study KB promotion: the home choice

> **Confirmed (2026-06-20) — Open Question 4 (capability-study KB home) → (a) NEW `host-tool-capabilities.md`:** the verified
> `capability-study.md` (feature-001) is promoted to a durable KB doc. Two homes were weighed:
>
> - **(a) NEW `host-tool-capabilities.md` (recommended).** A standalone primary KB doc
>   carrying the per-tool capability matrix (discovery/execution/activation/capability/
>   dispatchability + always-on verdict), structured so a 6th tool slots in identically
>   (NFR5). Pros: the study is a *reusable per-tool reference* with its own `intent:`
>   frontmatter, discoverable via INDEX; matches the study's "future-tool-extensible" design.
>   Cons: adds one KB doc → INDEX/README regen + one more reviewed-surface doc.
> - **(b) Addendum to `pipeline-contracts.md`'s Renderer Contract.** Fold the matrix into the
>   existing renderer-contract section. Pros: no new doc, no count change. Cons: the study is
>   *capability* knowledge, not a *pipeline interface contract* — a category mismatch; it bloats
>   an already-large doc and is harder to extend per-tool.
>
> **Recommended: (a) `host-tool-capabilities.md`** — the study is durable reference knowledge
> in its own right (it gates future format decisions and 6th-tool onboarding), and a dedicated
> doc is the honest category. Choosing (a) is the trigger for the INDEX/README regen in §B.3(v).
> *(Confirmed 2026-06-20: option (a) — a new `host-tool-capabilities.md` KB doc.)*

---

### Feature Flow — Lockstep-update → Regen → Gate

This feature is **strictly last**; it depends on 001/002/003 having landed (their PRs merged
or their branches integrated into the work's delivery branch) so the gate runs against the
*settled* layout.

```
[PRECONDITION]  feature-001 DONE (capability-study.md w/ its decision section recorded; E-CODEX-1 verdict known)
                feature-002 DONE (generator collapsed; profiles/* reshaped; EMISSION-MANIFEST
                                  updated; dead tests deleted + CI de-wired; dogfood guard added)
                feature-003 DONE (aid update/add + install-libs migrate; migration tests pass)
                    │
                    ▼
[L1 LOCKSTEP]  Update the residual dependents (Layers §B):
               • release.sh codex roots (B.1)
               • docs/*.md layout edits → run sync-docs.mjs → commit site/* (B.2)
               • hand-edit installation.mdx + cli.mdx (B.2)
               • CONTRIBUTING.md + profile READMEs (delineation table)
               • KB: content-isolation R6 (B.3.i) + glossary/integration-map/
                 pipeline-contracts/architecture term-retirement (B.3.ii-iii)
               • promote capability-study → host-tool-capabilities.md (B.3.iv / B.4)
               • release-tracking.md Unreleased [CHANGE] entries
                    │
                    ▼
[L2 REGEN]     build-kb-index.sh → INDEX.md ; update README.md ; (re-run gen-reference.mjs
               only if counts changed — they do not here, OQ3)
                    │  (gate: kb-hygiene INDEX-fresh check would pass locally)
                    ▼
[L3 GATE]      Final acceptance gate (Telemetry §): AC3 all-green CI + AC4 multi-tool repo
                    │  (gate: every CI job green AND the AC4 procedure passes/documents)
                    ▼
[L4 SHIP]      PR from the work-005 delivery branch → PR-protected master (C7); the agent
               pushes as the non-admin bot; the user merges + tags. release.sh runs at tag time.
```

There is **no auto-advance**; each step is human-reviewable, consistent with AID discipline.
L1 edits are pure content/packaging (no code), so they cannot themselves break a generator
or CLI gate — they can only break the **docs build** (stale cross-link/frontmatter) or
**version-sync**, both caught in L3.

---

### Telemetry & Tracking — The Final Acceptance Gate (AC3 + AC4)

#### AC3 — the exact green-CI checklist (post-collapse)

The gate asserts **every** CI job is green against the settled layout. The jobs, by workflow,
**as they exist after feature-002's CI de-wiring**:

| Workflow / job | What it runs | work-005 effect |
|----------------|--------------|-----------------|
| `test.yml` **render-drift** (`:24-42`) | `run_generator.py` + `git diff --exit-code -- profiles/` | Unchanged in shape; now the **copy** generator; profiles re-rendered + committed (002) so drift-free. |
| `test.yml` **canonical-tests** (`:44-80`) | `bash tests/run-all.sh` (glob-discovered suites) | **Suite count adjusts** — 002 adds `test-dogfood-byte-identity.sh`, 003 extends `test-aid-migrate.sh`; the deleted Python emitter tests were **not** in `run-all.sh` (they are `generator-selftests`), so the `tests/canonical/` count *grows*. KB INDEX `49` → reconcile (OQ2/OQ3). |
| `test.yml` **generator-selftests** (`:82-98`) | per-script `--self-test` | **002 de-wires** `test_copilot_emitter.py` + `test_antigravity_emitter.py` (`:97-98`) and re-points the `render_*` self-tests to `render.py --self-test`. AC3 confirms the **new** invocation list is green. |
| `test.yml` **kb-hygiene** (`:100-124`) | CRLF guard, `.aid/.temp` untracked, **INDEX fresh** (`build-kb-index.sh` + diff) | The KB edits + INDEX regen (L2) must leave this **green** — the single most likely AC3 failure for *this* feature's own edits. |
| `docs.yml` **build** (`:34-69`) | `npm ci` + `npm run build` (Astro Starlight; `prebuild` runs `gen-reference.mjs`) | Must be green after the `site/*` re-sync + hand-edits (B.2). Triggers on push:[master] / release / workflow_dispatch only — **NOT a PR gate** (docs.yml has no `pull_request` trigger), so the Astro build is verified **post-merge**, not on the delivery PR. |
| `docs.yml` **deploy** (`:75`) | Pages deploy | Post-merge; not a PR gate. |
| `installer-tests.yml` (Windows + Linux) | `Test-AidInstaller.ps1` + Linux installer suites | feature-003's CLI/migration changes must be green here (Windows runner). |
| `release.yml` **render-drift + selftests** (`:123,166-167`) | mirrors test.yml at release time | 002 de-wires `:166-167`; version-sync (`check-version-sync.sh` / `test-version-sync.sh`) green. |

**Suite-count reconciliation (OQ2/OQ3):** REQUIREMENTS AC3 says "53+ suites"; KB
`test-landscape.md`/INDEX say "49"; 002/003 add suites. The *literal* number is settled by the
on-disk glob at gate time, not by the doc.

> **Confirmed (2026-06-20) — Open Question 2 (reconciliation route) → inline semantics + housekeep numerics:** the stale counts live in **`test-landscape.md` ("49 suites")**, **`module-map.md`
> ("13 renderer Python files", "12/13 skills")**, and **INDEX.md summaries** that mirror them.
> These are *generator/test inventory* facts that **feature-002 changes** (13→4 scripts) and
> **002/003 grow** (new suites). Per the AID precedent that count-drift across many KB docs is
> reconciled via **`/aid-housekeep`** (memory: "adding-skill-kb-count-drift", Q26/Q27), the
> recommended route is: **feature-004 fixes the layout/term references inline** (R6, formats,
> split-layout, codex paths — the *semantic* edits), and **defers the pure numeric count
> reconciliation (script count, suite count) to a `/aid-housekeep` pass** so the numbers are
> taken from one authoritative on-disk sweep rather than hand-counted mid-flight. *(Confirmed 2026-06-20: inline semantics here; numeric counts deferred to a `/aid-housekeep` pass.)*

> **Confirmed (2026-06-20) — Open Question 3 (gen-reference / skill-agent counts) → no change:** work-005
> adds/removes **no** user-facing skill or agent (it collapses the *generator*, a
> maintainer-only skill, and deletes *tests*). So the "N user-facing skills" / "9 agents"
> counts in KB + the `gen-reference.mjs` site tables are **unaffected** — no count-drift
> housekeep on that axis. *(Confirmed 2026-06-20: no skill/agent inventory change in 002 — the `generate-profile` skill is maintainer-only and its count is not advertised.)*

#### AC4 — the multi-tool no-contamination acceptance test

A **real multi-tool repo** with claude-code + cursor + codex installed, each exercised, each
proven to use **only its own tree** with no cross-tree contamination.

> **Confirmed (2026-06-20) — Open Question 5 (AC4 mechanism) → two-part (durable structural suite + manual behavioral check):** the recommended
> mechanism is a **gated, repeatable acceptance procedure** (not a new permanent CI suite,
> which would need three live host-tool runtimes CI cannot provide):
>
> 1. In a throwaway repo, `aid add claude-code,cursor,codex` (one version, FR10/FR11 invariant).
> 2. **Structural assertion (automatable, the durable half):** confirm each tool's tree exists
>    with the uniform `{agents,skills,aid}` shape under its own root (`.claude/`, `.cursor/`,
>    `.codex/`), the same canonical skill/agent bodies are byte-identical across trees (AC1),
>    and **no tool's tree references another tool's root** (grep each tree for foreign root
>    basenames). This half can be a `tests/canonical/` bash suite and would then *also* be an
>    AC3-gated regression — recommended.
> 3. **Behavioral assertion (manual, tied to feature-001 AC4a / E-CODEX-1):** exercise the one
>    representative skill + agent across the work's **3-tool scenario — Cursor + Claude Code +
>    Codex** — per feature-001's parity criteria (the Codex run is gated on E-CODEX-1 landing
>    `high`/PASS; if it stays `docs`-only the Codex behavioral row is documented as a residual,
>    not silently dropped). **Copilot CLI + Antigravity behavioral parity is *asserted by the
>    Finding-D1 content-identity argument, not exercised*** (CI cannot run five live runtimes) —
>    named as a residual, aligned with AC4a. Confirm each tool runs *its own* content (the
>    original production bug was Cursor executing `.claude/` skills). Record pass, or document
>    any gap (NFR3 — never hidden).
>
> The structural half discharges AC4's "each tool uses its own tree / no contamination"
> mechanically and durably; the behavioral half ties to feature-001's AC4a verification (it is
> the *same* representative skill/agent + parity criteria, not a second study). *(Confirmed 2026-06-20: the two-part mechanism, with the structural half promoted to a permanent AC3-gated `tests/canonical/test-multitool-isolation.sh`.)*

Work state (this gate's pass/fail, the residual-edit checklist) is tracked in the work
`STATE.md` per AID discipline — **the orchestrator owns those writes; this spec registers
nothing** (per the task instruction).

---

### Migration Plan — doc/site/KB content sync only

There is **no data migration and no install migration** in this feature (install-time user-repo
migration is feature-003 FR7/AC5; output-tree reshape is feature-002). The only "migration" is
**content sync to the new layout**:

- the `docs/* → site/*` re-sync via `node site/scripts/sync-docs.mjs` (B.2), committing the
  regenerated `site/src/content/docs/{concepts,reference}/*` copies so the Astro build is current;
- the INDEX.md regen via `build-kb-index.sh` (B.3.v) so kb-hygiene stays green.

Both are deterministic, re-runnable, and idempotent. No fixtures, no rollback, no on-disk user
state is touched.

---

### Acceptance-Criteria Coverage

| AC | Where satisfied |
|----|-----------------|
| **AC3** — all CI green: render-drift, run-all (adjusted suite count), generator self-tests (post-collapse list), installer Win+Linux, docs Astro build, version-sync | Telemetry §AC3 checklist (the exact post-de-wire job/invocation list) + Feature Flow L3 |
| **AC4** — real multi-tool repo (claude-code+cursor+codex); each uses its own tree; no cross-contamination | Telemetry §AC4 (two-part mechanism: durable structural suite + manual behavioral check tied to feature-001 AC4a/E-CODEX-1) |
| **FR8** — dependents in lockstep (release packaging, docs, KB consistent with new layout) | Layers §A delineation + §B residual edits (release.sh, docs/site, CONTRIBUTING, READMEs, KB) |
| **FR2 / C1 / D1 (cross-ref Q3)** — content-isolation R6 revised for Codex `.codex/{agents,skills,aid}` | Layers §B.3.i (the concrete 3-spot R6 edit + changelog paper trail) |
| **feature-001 handoff** — capability-study promoted to durable KB at ship-time | Layers §B.3.iv + §B.4 (`host-tool-capabilities.md`, OQ4) + INDEX/README regen |
| **C7** — work lands via PR from a delivery branch to PR-protected master; bot pushes, user merges/tags | Feature Flow L4 |

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-20 | Technical Specification drafted (aid-specify): residual-vs-owned delineation table (no gap/overlap with 001/002/003); release.sh codex roots claimed as residual (OQ1); docs/* + sync-docs site re-sync + hand-edited installation.mdx/cli.mdx; KB lockstep — content-isolation R6 3-spot revision (cross-ref Q3) + domain-glossary/integration-map/pipeline-contracts/architecture term-retirement; capability-study promotion to new `host-tool-capabilities.md` (OQ4) + INDEX/README regen; AC3 post-de-wire green-CI checklist; AC4 two-part acceptance mechanism (durable structural suite + manual behavioral check tied to feature-001 AC4a/E-CODEX-1, OQ5); suite-count + generator-inventory reconciliation via inline-semantics + /aid-housekeep-numerics (OQ2/OQ3). 5 open questions raised. | /aid-specify |
