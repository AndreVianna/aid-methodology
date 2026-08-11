# term-inventory.md

> **Purpose:** Complete coined-term and shouted-code inventory for the KB plain-language work.
> One row per candidate term; every REQUIREMENTS.md §2 term appears with a define-versus-replace trade-off;
> every FR-4 shouted code is listed with its first-occurrence doc and resolution route.
> This document is the input for rewrite tasks task-006 through task-013.

## 1. Commands Run and Reproducibility

### Exact Commands (Reproducible)

```bash
# Working directory: /workspace/.cursor/worktrees/work-008
# Prerequisite: gawk (not mawk). See Finding F-1.

# Step 1 — KB harvest
bash canonical/aid/scripts/kb/harvest-coined-terms.sh \
  --root .aid/knowledge \
  --top 1200 \
  --output .aid/.temp/kb-language/harvest-kb.md

# Step 2 — Root harvest
bash canonical/aid/scripts/kb/harvest-coined-terms.sh \
  --root . \
  --top 1200 \
  --output .aid/.temp/kb-language/harvest-root.md

# Step 3 — Closure-check (KB candidates only; 18s)
bash canonical/aid/scripts/kb/closure-check.sh \
  --concepts .aid/.temp/kb-language/harvest-kb.md \
  --spine .aid/knowledge/domain-glossary.md \
  --kb-dir .aid/knowledge \
  --output-a .aid/.temp/kb-language/closure-a-kb-only.md \
  --output-b .aid/.temp/kb-language/closure-b-kb-only.md

# Step 4 — Verification runs (re-run Steps 1-2 with new output paths)
bash canonical/aid/scripts/kb/harvest-coined-terms.sh \
  --root .aid/knowledge --top 1200 \
  --output .aid/.temp/kb-language/harvest-kb-verify.md

bash canonical/aid/scripts/kb/harvest-coined-terms.sh \
  --root . --top 1200 \
  --output .aid/.temp/kb-language/harvest-root-verify.md
```

### Harvest Statistics

| Harvest | Run date | Candidates (post-denylist) | Top emitted | Verify candidates |
|---------|----------|---------------------------|-------------|-------------------|
| `--root .aid/knowledge` | 2026-08-11 | 1114 | 1114 | 1114 — identical term set |
| `--root .` | 2026-08-11 | 58128 | 817 | 58183 — +55 git-log commits; term SET identical |

**Reproducibility result:** KB harvest is CONFIRMED stable (identical candidate set both runs;
no history channel). Root harvest term SET is stable but candidate count varies (+55) because
the `history` channel includes the last 500 git-log commits which changes between runs.
Impact: zero — the root harvest contributes no terms to the inventory that the KB harvest
does not already cover.

## 2. Findings (SPEC / REQUIREMENTS Factual Gaps)

### F-1 — `gawk` required but undeclared

`harvest-coined-terms.sh` uses gawk-specific multidimensional array syntax (`channels[term][channel]`).
The system default `awk` on standard Ubuntu/Debian is `mawk 1.3.4`, which fails with
`syntax error at or near [`. `technology-stack.md` does not list `gawk` as a required tool;
neither SPEC.md nor REQUIREMENTS.md mentions it. Any reader who follows Flow A on a standard
image will get a silent fail. **Action:** add `gawk` to `technology-stack.md` toolchain section.

### F-2 — KB-coined phrases composed of common words are structurally invisible to the harvest

The following REQUIREMENTS.md §2 example terms are absent from both harvest outputs:
`load-bearing`, `render-drift`, `kind-sibling`, `thin doorway`, `fat pipeline`,
`hand-authored collapse`, `lockstep`, `HOME-pinning`.

Root cause: these terms' component words are all common English (in the denylist). The harvest
allows such phrases through ONLY if their cross-channel `spread >= 2`. KB docs all land in the
single `docs` channel, so any KB-prose-only phrase has `spread = 1` and is filtered.

SPEC.md §Flow A states the KB-only harvest *'catches a term coined only in KB prose — the
dominant case in REQUIREMENTS.md §2'* — but all eight §2 sample terms are multi-word lowercase
phrases composed of common words, and none survives the denylist. The claim is factually
inaccurate. Supplemental entries below cover these terms; task-002 should track this as a
harvest coverage gap for the `--root .aid/knowledge` recipe.

### F-3 — `--defined-extra` performance regression

`closure-check.sh` has a pre-committed `--defined-extra` flag (Task-002 work-in-progress).
Running it against the merged 58k-row candidates.md took >4 minutes and was killed (vs. 18s
without it). Manual triage of Lexicon/Abbreviations terms was performed instead, as specified
in DETAIL.md for the case where the flag is absent or non-functional.

### F-4 — Pre-existing uncommitted production files on this branch

`git status --porcelain -- .aid/knowledge canonical tests` shows pre-existing changes on the
`work-008` branch: `canonical/aid/scripts/kb/closure-check.sh` (modified),
`tests/canonical/test-ascii-only.sh` (modified), `canonical/aid/scripts/kb/kb-language-lint.sh`
(untracked). These pre-date this task execution and are unrelated to this RESEARCH task.
This task changed no production file.

### Open question — State-name casing in KB prose

State-machine state names (ELICIT, GENERATE, REVIEW, Q-AND-A, FIX, APPROVAL, DONE,
DESCRIBE-SEED, INTAKE, CAPTURE, SPEC, PLAN, DETAIL, GATE, APPROVAL-HALT) appear as ALL-CAPS
tokens throughout KB docs. Whether they should remain ALL-CAPS or be normalised to lower case
in KB prose is a plain-language design decision that affects 19+ shouted codes. This inventory
assigns `define` to them; the rewrite tasks should make the casing decision.

## 3. Shouted-Code Inventory (FR-4 Complete)

**Total shouted-code classes found:** 19
All entries identified by manual KB sweep; none appear in the harvest output.

| # | term | first-occurrence doc | legend today? | disposition | resolution route |
|---|------|---------------------|---------------|-------------|-----------------|
| 1 | `CONFIRMED` | architecture.md (first) | yes | **define** | add a named legend in authoring-conventions.md §Evidence Tags defining CONFIRMED (verified in source), SYNTHESIS (cross-source conclusion), UNCERTAIN (weak signal). Glossary placement: Lexicon — KB Au |
| 2 | `SYNTHESIS` | architecture.md (first occurrence line 73) | yes | **define** | define alongside CONFIRMED in authoring-conventions.md §Evidence Tags. Glossary placement: Lexicon — KB Authoring |
| 3 | `ELICIT / ELICIT E1/E2` | architecture.md (first) | no | **define** | add state-machine states to Lexicon — Pipeline Run-State with cross-reference to canonical/skills/aid-discover/SKILL.md. Glossary placement: Lexicon — Pipeline Run-State |
| 4 | `APPROVAL-HALT` | architecture.md (first) | yes | **define** | add to Lexicon — Pipeline Run-State. Glossary placement: Lexicon — Pipeline Run-State |
| 5 | `S1-S5` | INDEX.md (first) | yes | **define** | add S1-S5 to domain-glossary.md Abbreviations table with cross-reference to test-landscape.md § S1-S5. Glossary placement: Abbreviations & Acronyms table |
| 6 | `T1-T6` | artifact-schemas.md (T3 first) | yes | **define** | add T1-T6 to domain-glossary.md Abbreviations table with cross-reference to test-landscape.md § T1-T6. Glossary placement: Abbreviations & Acronyms table |
| 7 | `P1 / P3 / P5 / P7 / P9 / P10 (kb-authoring principles)` | authoring-conventions.md (first and primary) | yes | **define** | add "kb-authoring Pn" to domain-glossary.md Abbreviations table with cross-reference to authoring-conventions.md, listing all used principle numbers. Glossary placement: Abbreviations & Acronyms table |
| 8 | `C0-C9 (concern/dimension IDs)` | All 17 KB docs (frontmatter tags field) | yes | **define** | add C0-C9 dimension table to domain-glossary.md Abbreviations table, listing each ID and its scope. Glossary placement: Abbreviations & Acronyms table |
| 9 | `GENERATE / REVIEW / Q-AND-A / FIX / APPROVAL / DONE (aid-discover states)` | architecture.md (first) | yes | **define** | add state machine state names (ELICIT, GENERATE, REVIEW, Q-AND-A, FIX, APPROVAL, DONE, DESCRIBE-SEED, COMPLETION, FIRST-RUN, CONTINUE) to Lexicon — Pipeline Run-State as a table. Glossary placement: L |
| 10 | `INTAKE / CAPTURE / SPEC / PLAN / DETAIL / GATE / APPROVAL-HALT (shortcut engine states)` | architecture.md (first) | yes | **define** | add shortcut engine state sequence to Lexicon — Pipeline Run-State with cross-reference to shortcut-engine.md. Glossary placement: Lexicon — Pipeline Run-State |
| 11 | `VERIFY (deterministic)` | architecture.md (first) | yes | **define** | add to Lexicon — Build, Render and Install Mechanics. Closely related to render-drift (the CI job name). Glossary placement: Lexicon — Build, Render and Install Mechanics |
| 12 | `W-series / W1-N / W5-N (tech-debt IDs)` | tech-debt.md (primary) | yes | **dismiss** | No independent definition needed in glossary; table structure is self-documenting |
| 13 | `D1-D26 (decision record IDs)` | decisions.md (primary) | yes | **dismiss** | Self-documenting via decisions.md table of contents |
| 14 | `SEC-1..4 (security invariants)` | domain-glossary.md (defined) | yes | **define** | Already defined — Abbreviations table entry "SEC-1..4" = security invariants for dashboard server (loopback-only bind SEC-1, read-only SEC-3, no LLM import SEC-4) |
| 15 | `NFR-7` | architecture.md | yes | **define** | Already defined — Concept Spine entry "NFR-7 Suggested-Answer + Rationale" |
| 16 | `E1/E2 (ELICIT sub-steps)` | artifact-schemas.md (first) | yes | **define** | include in the ELICIT/aid-discover state machine glossary entry (Lexicon — Pipeline Run-State). Glossary placement: Lexicon — Pipeline Run-State (as sub-steps of ELICIT) |
| 17 | `R0-R5 (reconcile steps)` | artifact-schemas.md (first) | yes | **define** | add to Lexicon — Connectors alongside E1/E2. Glossary placement: Lexicon — Connectors |
| 18 | `Q10 (open question ID)` | architecture.md | yes | **dismiss** | STATE.md question identifiers are ephemeral; Q10 is cited for traceability only |
| 19 | `L4 (tech-debt effectiveness program)` | decisions.md | yes | **dismiss** | Category identifiers in tech-debt.md are local numeric labels |

## 4. REQUIREMENTS.md §2 Required Terms — Define-vs-Replace Analysis

Every term REQUIREMENTS.md §2 names, with an explicit define-versus-replace trade-off.
*(supplemental)* = not captured by the harvest (see F-2).

| term | in harvest? | docs (sample) | glossary status today | disposition | define-vs-replace trade-off |
|------|------------|---------------|----------------------|-------------|----------------------------|
| `load-bearing` | no *(supplemental)* | architecture.md, artifact-schemas.md, authoring-conventions.md, … | not defined | **replace** | Construction-trade metaphor used as adjective meaning "fundamental" or "essential". Examples: "load-bearing term", "load-bearing boundaries", "load-bearing design". Replace with "fundamental", "essential", or "critical" throughout. Define-vs-replace trade-off: defining it would enshrine a metaphor that adds no AID-specific precision; replacing it removes jargon and improves plain-language clarity (FR-3). High volume (~216 occurrences across 12+ docs) makes replacement invasive but unambiguous. |
| `Concept Spine` | yes | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry. Retain. Define-vs-replace trade-off: "Concept Spine" is the project's central terminological artifact; replacing it with "ubiquitous language" or "glossary" would break many cross-references (it is used in 59 places). Define is the clear choice; the term is already in place. Aliases: "Ubiquitous Language", "Declared Concept-Spine". |
| `dogfood` | no *(supplemental)* | architecture.md, decisions.md, domain-glossary.md, … | defined — Concept Spine (Dual-Face Dogfood Repository) | **alias** | Short informal form of "Dual-Face Dogfood Repository" (Concept Spine). Used as verb ("the repo dogfoods itself") and adjective ("dogfood trees"). Acceptable in prose; add as **Aliases:** entry on the Dual-Face Dogfood Repository spine entry. Define-vs-replace trade-off: the full concept is already defined; no standalone definition needed. An alias annotation suffices. |
| `kind-sibling` | no *(supplemental)* | INDEX.md, module-map.md | not defined | **define** | One of four skill structural shapes: a skill that delegates to a sibling skill rather than the shortcut engine. Named in module-map.md §Skill Structural Shapes. Define-vs-replace trade-off: replacing with "sibling-delegating skill" or "skill that delegates to another skill" is verbose and loses the structural taxonomy the table establishes. Define as Lexicon — KB Authoring or new Lexicon — Skill Structural Shapes entry. Glossary placement: Lexicon table (Skill Structural Shapes). |
| `thin doorway` | no *(supplemental)* | capability-inventory.md, decisions.md, pipeline-contracts.md | not defined | **alias** | Informal alias for the "Generated shortcut doorway" structural shape (module-map.md §Skill Structural Shapes table). Used in prose before the table introduced the canonical name. Define-vs-replace trade-off: replace "thin doorway" inline with "generated shortcut doorway" (the table's canonical name), OR define it as an alias in the Lexicon entry for Generated shortcut doorway. Recommendation: replace in prose; the table already carries the canonical name. |
| `fat pipeline` | no *(supplemental)* | INDEX.md, module-map.md | not defined | **define** | One of four skill structural shapes: a skill with a ## Dispatch table mapping states to references/state-*.md workers; no inline ## State: sections. Named in module-map.md §Skill Structural Shapes. Define-vs-replace trade-off: the term is already a coined name in the module-map table (full form: "Fat pipeline skill"); replacing it with a longer description loses the compact taxonomy. Define in Lexicon — Skill Structural Shapes. Glossary placement: Lexicon table (Skill Structural Shapes). |
| `hand-authored collapse` | no *(supplemental)* | INDEX.md, module-map.md | not defined | **define** | One of four skill structural shapes: a skill with six inline ## State: sections inside SKILL.md itself; self-contained, no delegation to reference files. Named in module-map.md §Skill Structural Shapes. Define-vs-replace trade-off: this is a coined taxonomy name and should be defined; replacing loses the structural classification. Glossary placement: Lexicon table (Skill Structural Shapes). |
| `lockstep` | no *(supplemental)* | architecture.md, infrastructure.md, integration-map.md, … | not defined | **replace** | Military/marching metaphor meaning "must change together, in coordinated fashion". Used in "the five install manifests must move in lockstep" (architecture.md), "install manifests stay in lockstep" (module-map.md), "a lockstep change" (integration-map.md). Define-vs-replace trade-off: defining it would canonize a metaphor; replacing with "synchronized" or "must change together" is clearer plain language. Where it names a specific invariant (the five-manifest invariant), that constraint belongs in Lexicon — Build, Render and Install Mechanics under its own entry rather than under the word "lockstep". |
| `render-drift` | no *(supplemental)* | architecture.md, infrastructure.md, integration-map.md, … | not defined | **define** | Specific CI gate and condition name: the state where profiles/ has diverged from canonical/ across a re-render pass. Not a generic term — it IS the gate/job name (test.yml job: render-drift). Cannot be replaced with plain words without renaming the CI job. Define-vs-replace trade-off: this term IS the gate name; defining it in Lexicon — Build, Render and Install Mechanics gives readers a clear reference point. Glossary placement: Lexicon — Build, Render and Install Mechanics. |
| `HOME-pinning` | no *(supplemental)* | INDEX.md (tech-debt.md summary), tech-debt.md, test-landscape.md | not defined | **define** | Specific operational hazard: the migration-scan script defaults its root to $HOME, causing unintentionally wide filesystem scans if not guarded. Named in tech-debt.md and test-landscape.md §HOME-pinning hazard. Define-vs-replace trade-off: this term labels a concrete, named gotcha; a glossary entry makes it findable. Define in Lexicon — Install and CLI. Glossary placement: Lexicon — Install and CLI. |

## 5. Formatted `.glossary-dismissed.txt` Entries

The entries below use the required SPEC format: one `#` comment line (the reason) immediately
above the bare term. Copy directly into `.aid/knowledge/.glossary-dismissed.txt`.

This section lists representative dismiss entries for terms that appear in KB docs and need
a recorded reason. Common-word and code-identifier dismissals are grouped by class below.

### Specific coined-term dismissals (for .glossary-dismissed.txt)

```
# Three-letter abbreviation already defined in Abbreviations table; not a coined concept
aid

# AID-prefixed technical term; defined in context or documented as script/module name
aid installer bootstrap

# AID-prefixed technical term; defined in context or documented as script/module name
aid lite

# AID-prefixed technical term; defined in context or documented as script/module name
aid update self if

# AID-prefixed technical term; defined in context or documented as script/module name
aidinstaller

# AID-prefixed technical term; defined in context or documented as script/module name
aidnoun

# AID-prefixed technical term; defined in context or documented as script/module name
aidtool

# AID-prefixed technical term; defined in context or documented as script/module name
aidverbose

# AID-prefixed technical term; defined in context or documented as script/module name
how aid is tested

# AID-prefixed technical term; defined in context or documented as script/module name
mermaid cached

# AID-prefixed technical term; defined in context or documented as script/module name
mermaid version

# AID-prefixed technical term; defined in context or documented as script/module name
no mermaid engine

# AID-prefixed technical term; defined in context or documented as script/module name
no-mermaid-engine assertion

# Widely-known versioning convention (Semantic Versioning); not AID-coined
semver

# AID-prefixed technical term; defined in context or documented as script/module name
the aid dashboard component

# AID-prefixed technical term; defined in context or documented as script/module name
why aid

# AID-prefixed technical term; defined in context or documented as script/module name
why aid is polyglot

# Bulk pattern: split-compound harvest artifacts (all PascalCase phrase forms where
# the joined camelCase version is defined separately — e.g., 'Aid Install Core' / 'AidInstallCore')
# Harvest artifact: split form of camelCase term. No standalone definition needed.
additional child path

# Harvest artifact: split form of camelCase term. No standalone definition needed.
advance types

# Harvest artifact: split form of camelCase term. No standalone definition needed.
aid gitignore block

# Harvest artifact: split form of camelCase term. No standalone definition needed.
aid home t39

# Harvest artifact: split form of camelCase term. No standalone definition needed.
aid install core

# Bulk pattern: product names and proper nouns
# Widely-known product/proper name; not AID-coined.
andre vianna

# Widely-known product/proper name; not AID-coined.
claude code

# Widely-known product/proper name; not AID-coined.
git hub

# Widely-known product/proper name; not AID-coined.
github

# Widely-known product/proper name; not AID-coined.
java script

```

> **Note:** The full set of 1008 dismiss entries would overwhelm `.glossary-dismissed.txt`.
> Task-006 should determine which dismissed terms genuinely need explicit records (i.e., those
> that a reviewer might flag as glossary gaps) and add only those. Common single words,
> section headings, and camelCase artifacts do not need explicit dismissal records.

## 6. Full Term Inventory

**Total candidate terms:** 1134 &nbsp; |
**define:** 90 &nbsp; |
**alias:** 6 &nbsp; |
**replace:** 30 &nbsp; |
**dismiss:** 1008

Section codes: `kb-harvest` = from KB-only harvest (`--root .aid/knowledge`);
`supplement-s2` = §2 manual addition (not in harvest; see F-2);
`shouted-codes` = FR-4 sweep (all supplemental).

For `define` rows, the `reason` column states whether the term goes to **Concept Spine** or a **Lexicon table**.
For `dismiss` rows, the `reason` column is verbatim text suitable as a `#` comment in `.glossary-dismissed.txt`.

| term | harvest channel(s) | docs where used | glossary status today | disposition | reason or proposed replacement |
|------|-------------------|-----------------|----------------------|-------------|-------------------------------|
| `a minimal KB` | docs | pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Acceptance Criteria` | docs,history | artifact-schemas.md, domain-glossary.md, pipeline-contracts.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Active Findings` | docs | pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Active Skill` | docs | artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Adaptive Loop` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Added Unit` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Adding Power` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Additional Child Path` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AdditionalChildPath". No standalone definition needed. |
| `AdditionalChildPath` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Adds Test` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Adds Tier` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Advance` | docs | STATE.md, architecture.md, artifact-schemas.md, authoring-conventions.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Advance Types` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AdvanceTypes". No standalone definition needed. |
| `AdvanceTypes` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Agent Dispatch` | docs | INDEX.md, architecture.md, coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Agent Dispatch Model` | docs | architecture.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `AI Integrated Development` | docs | README.md, capability-inventory.md, domain-glossary.md, project-structure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `aid` | docs | INDEX.md, README.md, STATE.md, architecture.md, … | defined — glossary table | **dismiss** | Three-letter abbreviation already defined in Abbreviations table; not a coined concept. |
| `Aid Gitignore Block` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidGitignoreBlock". No standalone definition needed. |
| `Aid Home T39` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidHomeT39". No standalone definition needed. |
| `Aid Install Core` | docs,history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidInstallCore". No standalone definition needed. |
| `Aid Installer` | docs,history | project-structure.md, relationships.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidInstaller". No standalone definition needed. |
| `AID installer bootstrap` | docs | project-structure.md, relationships.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AID Lite` | docs | release-tracking.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `Aid Manifest` | docs,history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidManifest". No standalone definition needed. |
| `Aid Migrate Repo` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidMigrateRepo". No standalone definition needed. |
| `Aid Noun` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidNoun". No standalone definition needed. |
| `Aid Projects Scan` | history | release-tracking.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidProjectsScan". No standalone definition needed. |
| `Aid Scaffold Bare Project` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidScaffoldBareProject". No standalone definition needed. |
| `Aid Scan Config Path` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidScanConfigPath". No standalone definition needed. |
| `Aid Scan Config Seed` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidScanConfigSeed". No standalone definition needed. |
| `Aid Scan Merged Prune Dirs` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidScanMergedPruneDirs". No standalone definition needed. |
| `Aid Scan Prune Dir From Config` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidScanPruneDirFromConfig". No standalone definition needed. |
| `Aid Scan Prune Dirs` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidScanPruneDirs". No standalone definition needed. |
| `Aid Scan Root` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidScanRoot". No standalone definition needed. |
| `Aid Scan System Dirs` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidScanSystemDirs". No standalone definition needed. |
| `Aid Scan Walk` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidScanWalk". No standalone definition needed. |
| `Aid Scan Walk Node` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidScanWalkNode". No standalone definition needed. |
| `Aid State Home` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidStateHome". No standalone definition needed. |
| `Aid Status Body` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidStatusBody". No standalone definition needed. |
| `Aid Supported Format` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidSupportedFormat". No standalone definition needed. |
| `Aid Timestamp` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidTimestamp". No standalone definition needed. |
| `Aid Tool` | docs | architecture.md, project-structure.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidTool". No standalone definition needed. |
| `Aid Update All` | history | release-tracking.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidUpdateAll". No standalone definition needed. |
| `Aid Update Self If` | docs | domain-glossary.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `Aid Verbose` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidVerbose". No standalone definition needed. |
| `Aid Version` | docs,history | STATE.md, artifact-schemas.md, capability-inventory.md, domain-glossary.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AidVersion". No standalone definition needed. |
| `aid-ask` | docs | architecture.md, capability-inventory.md, pipeline-contracts.md, relationships.md, release-tracking.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create` | docs | architecture.md, capability-inventory.md, decisions.md, domain-glossary.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-api` | docs | architecture.md, capability-inventory.md, decisions.md, domain-glossary.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-cli` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-config` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-dashboard` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-data-model` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-data-pipeline` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-diagram` | docs | capability-inventory.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-document` | docs | capability-inventory.md, module-map.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-infra` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-integration` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-job` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-messaging` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-test` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-theme` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-create-ui` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-define` | docs | (not found in KB body text) | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-deploy` | docs | STATE.md, architecture.md, artifact-schemas.md, capability-inventory.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-deprecate` | docs | capability-inventory.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-describe elicitation engine` | docs | capability-inventory.md, module-map.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-design` | docs | capability-inventory.md, domain-glossary.md, module-map.md, relationships.md, release-tracking.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-developer` | docs | architecture.md, decisions.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-discover` | docs | INDEX.md, STATE.md, architecture.md, artifact-schemas.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-document` | docs | capability-inventory.md, decisions.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-document-architecture` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-document-changelog` | docs | relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `aid-document-decision` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-document-guideline` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-document-runbook` | docs | decisions.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-document-standard` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-document-tutorial` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-execute` | docs | STATE.md, architecture.md, artifact-schemas.md, capability-inventory.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-experiment` | docs | capability-inventory.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-fix` | docs | architecture.md, capability-inventory.md, decisions.md, domain-glossary.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-housekeep` | docs | STATE.md, architecture.md, capability-inventory.md, domain-glossary.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-migrate` | docs | capability-inventory.md, domain-glossary.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-monitor` | docs | STATE.md, architecture.md, capability-inventory.md, decisions.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-node-panel` | docs | tech-debt.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-plan` | docs | STATE.md, architecture.md, artifact-schemas.md, capability-inventory.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-prototype` | docs | capability-inventory.md, module-map.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-prototype-ui` | docs | capability-inventory.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-refactor` | docs | capability-inventory.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-remove` | docs | capability-inventory.md, domain-glossary.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-report` | docs | capability-inventory.md, domain-glossary.md, module-map.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-research` | docs | STATE.md, architecture.md, capability-inventory.md, decisions.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-researcher` | docs | STATE.md, architecture.md, decisions.md, relationships.md, release-tracking.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-review` | docs | STATE.md, architecture.md, authoring-conventions.md, capability-inventory.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-reviewer` | docs | STATE.md, architecture.md, authoring-conventions.md, quality-gates.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-set-connector` | docs | relationships.md, release-tracking.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-specify` | docs | STATE.md, architecture.md, artifact-schemas.md, capability-inventory.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-summarize` | docs | STATE.md, architecture.md, artifact-schemas.md, authoring-conventions.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-tech-writer` | docs | STATE.md, architecture.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-test` | docs | capability-inventory.md, module-map.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-test-data-quality` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-test-performance` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-test-security` | docs | module-map.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-unset-connector` | docs | relationships.md, release-tracking.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update` | docs | STATE.md, architecture.md, capability-inventory.md, domain-glossary.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-api` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-cli` | docs | capability-inventory.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-config` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-dashboard` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-data-model` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-data-pipeline` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-document` | docs | capability-inventory.md, module-map.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-infra` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-integration` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-job` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-kb` | docs | STATE.md, architecture.md, capability-inventory.md, module-map.md, … | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-messaging` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-test` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-theme` | docs | relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `aid-update-ui` | docs | domain-glossary.md, relationships.md | not defined | **dismiss** | AID command/skill name. Documented in capability-inventory.md; no glossary entry needed. |
| `AID_HOME` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry (AID_HOME). |
| `AidGitignoreBlock` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidHomeT39` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidInstallCore` | docs,history | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry (AidInstallCore). |
| `AidInstaller` | docs,history | domain-glossary.md, module-map.md, project-structure.md, relationships.md, … | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidManifest` | docs,history | artifact-schemas.md, coding-standards.md | defined — glossary table | **define** | TypeScript type representing install manifests. Already in context as related to AidInstallCore. Add to Lexicon — Install and CLI. |
| `AidMigrateRepo` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidNoun` | docs | coding-standards.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidProjectsScan` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidScaffoldBareProject` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidScanConfigPath` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidScanConfigSeed` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidScanMergedPruneDirs` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidScanPruneDirFromConfig` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidScanPruneDirs` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidScanRoot` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidScanSystemDirs` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidScanWalk` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidScanWalkNode` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidStateHome` | docs | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidStatusBody` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — Lexicon table (AidVersion / AidStatusBody / AidSupportedFormat). |
| `AidSupportedFormat` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — Lexicon table. |
| `AidTimestamp` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidTool` | docs | artifact-schemas.md, coding-standards.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidUpdateAll` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidVerbose` | docs | coding-standards.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `AidVersion` | docs,history | domain-glossary.md | defined — glossary table | **define** | Already defined — Lexicon table. |
| `All Skills` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `An Astro` | docs | project-structure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Analyst Engine` | docs | STATE.md, architecture.md, domain-glossary.md, relationships.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Andre Vianna` | docs,history | (not found in KB body text) | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `AndreVianna` | docs,history | domain-glossary.md, infrastructure.md | defined — glossary table | **dismiss** | Author name / GitHub handle; not an AID concept. |
| `Apply Spacing` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ApplySpacing". No standalone definition needed. |
| `Apply Stage Transform` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ApplyStageTransform". No standalone definition needed. |
| `ApplySpacing` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ApplyStageTransform` | history | (not found in KB body text) | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Apps App` | history | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Artifact Condition` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ArtifactCondition". No standalone definition needed. |
| `Artifact Schemas` | docs | artifact-schemas.md, module-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ArtifactCondition` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Artifacts Reference` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `As Hashtable` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AsHashtable". No standalone definition needed. |
| `as of 2026-05-22` | docs | authoring-conventions.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `As Uncloneable` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AsUncloneable". No standalone definition needed. |
| `Ascii State Map` | history | module-map.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AsciiStateMap". No standalone definition needed. |
| `AsciiStateMap` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `AsHashtable` | history | (not found in KB body text) | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Assert test runtimes present` | docs | test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Asset Kinds` | docs | STATE.md, architecture.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Assets Present` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AssetsPresent". No standalone definition needed. |
| `AssetsPresent` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `astro build` | docs | architecture.md, integration-map.md, tech-debt.md, technology-stack.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `astro check` | docs | technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Astro Starlight` | docs | infrastructure.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `AsUncloneable` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Attribute Error` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "AttributeError". No standalone definition needed. |
| `AttributeError` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Audience Standard` | docs,history | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Authored Seed` | docs | architecture.md, capability-inventory.md, domain-glossary.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Authoring Conventions` | docs | authoring-conventions.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Authoring rules` | docs | INDEX.md, authoring-conventions.md, coding-standards.md, module-map.md, quality-gates.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `authoritative safety boundary` | docs | architecture.md, decisions.md, domain-glossary.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Azure Boards` | docs | infrastructure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `baseline unknown` | docs | artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Bash Exe` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "BashExe". No standalone definition needed. |
| `BashExe` | history | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Bearing Boundaries` | docs | architecture.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Bespoke Bash` | docs | test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Bespoke Power` | docs | test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Blind Reconstruction` | docs | quality-gates.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Block Artifact` | docs | artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Block Reason` | docs | artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Blocking vs Advisory` | docs | quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Bootstrap` | docs | INDEX.md, STATE.md, architecture.md, capability-inventory.md, … | not defined | **dismiss** | Standard software development term; not AID-coined. |
| `Branch isolation` | docs | domain-glossary.md, integration-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `build` | docs | (not found in KB body text) | not defined | **dismiss** | Standard software development term; not AID-coined. |
| `Build Commands` | docs | relationships.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Build Execution Graph` | docs | domain-glossary.md, pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Build Files Tree` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "BuildFilesTree". No standalone definition needed. |
| `BuildFilesTree` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `builds` | docs | architecture.md, artifact-schemas.md, capability-inventory.md, integration-map.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Bundle Checksum` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "BundleChecksum". No standalone definition needed. |
| `BundleChecksum` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Bypassing Execute` | docs | decisions.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Calibration Log` | docs | (not found in KB body text) | defined — glossary table | **define** | Already defined — Lexicon — Work Artifacts table. |
| `Candidate Concepts` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Candidate Concepts". |
| `Canonical` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Canonical". |
| `Capabilities Config` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "CapabilitiesConfig". No standalone definition needed. |
| `CapabilitiesConfig` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Capability Inventory` | docs | capability-inventory.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Card Grid` | docs,history | domain-glossary.md | defined — glossary table | **define** | Already defined — Lexicon — UI Components table (CardGrid / Card Grid). |
| `CardGrid` | docs,history | domain-glossary.md | defined — glossary table | **define** | Already defined — Lexicon — UI Components table (CardGrid / Card Grid). |
| `Change Log` | docs,history | README.md, architecture.md, artifact-schemas.md, authoring-conventions.md, … | defined — glossary table | **define** | Already defined — Lexicon table. |
| `Change Log Rev` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Change Plan` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Change Request` | docs | architecture.md, capability-inventory.md, decisions.md, domain-glossary.md, pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `check` | docs | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Child Args` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ChildArgs". No standalone definition needed. |
| `ChildArgs` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Churn Modules` | docs | module-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Circuit breaker` | docs | pipeline-contracts.md, quality-gates.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Citation Rule` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Claude Code` | docs,history | architecture.md, artifact-schemas.md, capability-inventory.md, decisions.md, … | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `Clear Layer` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ClearLayer". No standalone definition needed. |
| `ClearLayer` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `CLI installer capabilities` | docs | capability-inventory.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Cli Path Arg` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "CliPathArg". No standalone definition needed. |
| `CliPathArg` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Clock Win` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `closed items` | docs | authoring-conventions.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Code Cache` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Code Discrepancies` | docs | architecture.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Coding Standards` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Command Path` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "CommandPath". No standalone definition needed. |
| `CommandPath` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Common Mark` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "CommonMark". No standalone definition needed. |
| `CommonMark` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Compare Rows` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "CompareRows". No standalone definition needed. |
| `CompareRows` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Compat Lane` | docs | relationships.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Complete Methodology` | docs | architecture.md, project-structure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Completeness` | docs | INDEX.md, README.md, STATE.md, domain-glossary.md, relationships.md, release-tracking.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Complexity Hotspots` | docs | relationships.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Concept Spine` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry. Retain. Define-vs-replace trade-off: "Concept Spine" is the project's central terminological artifact; replacing it with "ubiquitous language" or "glossary" would break many cross-references (it is used in 59 places). Define is the clear choice; the term is … |
| `Concern Model` | docs | authoring-conventions.md, relationships.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Configuration Access` | docs | coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Configuration Contract` | docs | pipeline-contracts.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Confirmed Scope` | history | STATE.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Conformance Check` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine (Conformance Check). |
| `Conformance Lane` | docs | architecture.md, capability-inventory.md, module-map.md, pipeline-contracts.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Connector Add Form` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ConnectorAddForm". No standalone definition needed. |
| `Connector Registry` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine (Connector Registry). |
| `Connector Registry Artifacts` | docs | artifact-schemas.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ConnectorAddForm` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Connectors` | docs | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Contact Us` | docs | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Content isolation` | docs | architecture.md, artifact-schemas.md, authoring-conventions.md, decisions.md, relationships.md, test-landscape.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Contents` | docs | STATE.md, architecture.md, artifact-schemas.md, authoring-conventions.md, … | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Continuous Integration` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Contracts` | docs | INDEX.md, README.md, STATE.md, architecture.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Control Manifest` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ControlManifest". No standalone definition needed. |
| `Control State` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ControlState". No standalone definition needed. |
| `ControlManifest` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ControlState` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Convention beats search` | docs | architecture.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Conventions` | docs | INDEX.md, README.md, STATE.md, architecture.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Convert From` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ConvertFrom". No standalone definition needed. |
| `ConvertFrom` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Core model` | docs | decisions.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Coverage Assessment` | docs | decisions.md, relationships.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Coverage Parity` | docs | integration-map.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `covers nothing` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Create Process` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "CreateProcess". No standalone definition needed. |
| `CreateProcess` | history | (not found in KB body text) | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Curated Index` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "CuratedIndex". No standalone definition needed. |
| `CuratedIndex` | history | (not found in KB body text) | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Current Grade` | docs | INDEX.md, STATE.md, artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Cutting Risk` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Cutting Risks` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `cycle-7` | docs | quality-gates.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `D1 Fixed Opener` | docs | domain-glossary.md, module-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Danger Zone` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "DangerZone". No standalone definition needed. |
| `DangerZone` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `dark` | docs | STATE.md, project-structure.md, release-tracking.md, tech-debt.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Dashboard` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine (Dashboard). |
| `Dashboard Node` | docs | technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Dashboard Python` | docs | technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Dashboard Reader` | docs | artifact-schemas.md, coding-standards.md, domain-glossary.md, infrastructure.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Dashboard Server` | docs | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Data Flow` | docs | architecture.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `data model` | docs | artifact-schemas.md, domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Date Time` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "DateTime". No standalone definition needed. |
| `DateTime` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Dead Code` | docs | INDEX.md, relationships.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Debt Inventory` | docs | relationships.md, tech-debt.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Declared Concept` | docs | artifact-schemas.md, domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Declared Doc` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `deduplicate` | docs | module-map.md, project-structure.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Define Phase` | docs | architecture.md, capability-inventory.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Delete Modal Explicit Render` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "DeleteModalExplicitRender". No standalone definition needed. |
| `Delete Pipeline` | history | (not found in KB body text) | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `DeleteModalExplicitRender` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Delivery` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Delivery". |
| `Delivery Gate` | docs,history | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine + Lexicon table. |
| `Delivery Gates` | docs | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Delivery Lifecycle` | docs | artifact-schemas.md, domain-glossary.md, pipeline-contracts.md, quality-gates.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Delivery State` | docs | (not found in KB body text) | defined — glossary table | **define** | Already defined — glossary table entry "Delivery State". |
| `Delta Refresh` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `dependencies` | docs | INDEX.md, artifact-schemas.md, decisions.md, domain-glossary.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Dependency Graph` | docs | STATE.md, architecture.md, module-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Deploy State` | docs | artifact-schemas.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `deployment` | docs | domain-glossary.md, infrastructure.md, pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Detailed Debt Items` | docs | relationships.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Detected Technologies` | docs,history | INDEX.md, project-structure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Directory Tree` | docs | project-structure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Discovery Domain` | docs | README.md, STATE.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Discovery Elicitation` | docs | pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Discovery Scratch Artifacts` | docs | artifact-schemas.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Discovery State` | docs | INDEX.md, STATE.md, artifact-schemas.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Discovery Triage` | docs | STATE.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Disk Work Hierarchy` | docs | INDEX.md, pipeline-contracts.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Dispatch Log` | docs | artifact-schemas.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Dispatch Logs` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Dispatch Parameter` | docs | module-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Distribute Architecture` | docs | INDEX.md, architecture.md, capability-inventory.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Distribution Chain` | docs | integration-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Distribution Channels` | docs | INDEX.md, capability-inventory.md, domain-glossary.md, infrastructure.md, integration-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `distribution plane` | docs | capability-inventory.md, module-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `DM-1 envelope` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `DM-2 model` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Doc Title` | docs | authoring-conventions.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Doc-vs-Code Discrepancies` | docs | architecture.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Document Layout` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Documentation Found` | docs | project-structure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Documents Status` | docs | (not found in KB body text) | defined — glossary table | **define** | Already defined — glossary table entry "Documents Status". |
| `dogfooding` | docs | decisions.md, module-map.md, tech-debt.md, test-landscape.md | not defined | **alias** | Verbal form of "dogfood"; alias for using the methodology on itself. Acceptable in informal prose; define as alias under Dual-Face Dogfood Repository. |
| `domain` | docs | INDEX.md, README.md, STATE.md, architecture.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Domain Glossary` | docs | capability-inventory.md, domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Domain Source` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Doorway Binding` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "DoorwayBinding". No standalone definition needed. |
| `Doorway Chart` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "DoorwayChart". No standalone definition needed. |
| `DoorwayBinding` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `DoorwayChart` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Draw Badge` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "DrawBadge". No standalone definition needed. |
| `Draw Frame` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "DrawFrame". No standalone definition needed. |
| `Draw Hover Label` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "DrawHoverLabel". No standalone definition needed. |
| `Draw Ring` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "DrawRing". No standalone definition needed. |
| `DrawBadge` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `DrawFrame` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `DrawHoverLabel` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `DrawRing` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Drift-Prone Content is Banned` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Drive Info` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "DriveInfo". No standalone definition needed. |
| `DriveInfo` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Driven Development` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Dual-Audience Standard` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Dual-Face Dogfood Repository` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry. Retain. |
| `Duplication` | docs | architecture.md, module-map.md, project-structure.md, relationships.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Durable Anchors` | docs | authoring-conventions.md, module-map.md, quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Edited Docs` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Element By Id` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ElementById". No standalone definition needed. |
| `Element Seed Model` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ElementById` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Emission Manifest` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine (Emission Manifest). |
| `EmissionManifest` | docs | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `End Line` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "EndLine". No standalone definition needed. |
| `EndLine` | history | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Enforcement` | docs | INDEX.md, authoring-conventions.md, relationships.md, release-tracking.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Engine Core` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "EngineCore". No standalone definition needed. |
| `Engine Overview` | docs | module-map.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `EngineCore` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Entry Points` | docs | architecture.md, domain-glossary.md, module-map.md, project-structure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Entry Shortcuts` | docs | capability-inventory.md, decisions.md, domain-glossary.md, pipeline-contracts.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Envelope Contract` | docs | capability-inventory.md, module-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `environmental` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Error Handling` | docs | INDEX.md, coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Every Files` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Exclusion Path` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ExclusionPath". No standalone definition needed. |
| `ExclusionPath` | docs | tech-debt.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Execute Review` | docs | pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Execution Control` | history | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Execution Graph` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine (Execution Graph). |
| `Execution Graphs` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Execution Policy` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ExecutionPolicy". No standalone definition needed. |
| `ExecutionPolicy` | docs | test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Exit Codes` | docs | INDEX.md, authoring-conventions.md, coding-standards.md, infrastructure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Explicit Render` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ExplicitRender". No standalone definition needed. |
| `ExplicitRender` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Export as Markdown` | docs | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Export as PDF` | docs | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Expressive Code` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `External Documentation` | docs | INDEX.md, STATE.md, artifact-schemas.md, capability-inventory.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `External Sources` | docs,history | architecture.md, external-sources.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Face Dogfood Repository` | docs | domain-glossary.md, relationships.md | not defined | **alias** | Truncated form of "Dual-Face Dogfood Repository"; same concept. Already defined — Concept Spine. |
| `Feature Flow` | docs | artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Feature Title` | docs | artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `features` | docs | INDEX.md, STATE.md, artifact-schemas.md, capability-inventory.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Features State` | docs | artifact-schemas.md, quality-gates.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Feedback Loop` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine (Feedback Loop). |
| `Feedback Loop Contracts` | docs | pipeline-contracts.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Feedback Loops` | docs | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `File Hash` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "File Hash". |
| `File Header Convention` | docs | coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `File Hierarchy` | docs | artifact-schemas.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `File Not Found Error` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "FileNotFoundError". No standalone definition needed. |
| `File Sync` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "FileSync". No standalone definition needed. |
| `File System` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "FileSystem". No standalone definition needed. |
| `Filename and Location` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `FileNotFoundError` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Files outside any manifest` | docs | architecture.md, artifact-schemas.md, decisions.md, module-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Files Registry` | docs | artifact-schemas.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `FileSync` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `FileSystem` | docs | decisions.md, release-tracking.md, tech-debt.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Fill Pool` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `First Search` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Five` | docs | INDEX.md, STATE.md, architecture.md, capability-inventory.md, … | not defined | **dismiss** | Common English word or phrase; not a coined concept. |
| `Five Git` | docs | domain-glossary.md, infrastructure.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `fix` | docs | INDEX.md, STATE.md, architecture.md, artifact-schemas.md, … | not defined | **dismiss** | Standard software development term; not AID-coined. |
| `Fixed Opener` | docs | domain-glossary.md, module-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Flattened Lite` | docs,history | INDEX.md, artifact-schemas.md, capability-inventory.md, decisions.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Flow Chart` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "FlowChart". No standalone definition needed. |
| `Flow Edge` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "FlowEdge". No standalone definition needed. |
| `Flow Node` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "FlowNode". No standalone definition needed. |
| `Flow Warnings` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "FlowWarnings". No standalone definition needed. |
| `FlowChart` | history | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `FlowEdge` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `FlowNode` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `FlowWarnings` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `For Each` | docs | artifact-schemas.md, domain-glossary.md, release-tracking.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ForEach". No standalone definition needed. |
| `ForEach` | docs | coding-standards.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Forward-Authored Seed` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine (Forward-Authored Seed). |
| `Four Git` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Four GitHub Actions workflows` | docs | STATE.md | not defined | **dismiss** | GitHub platform term; not AID-coined. |
| `Fragment List` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "FragmentList". No standalone definition needed. |
| `FragmentList` | history | (not found in KB body text) | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `From Point` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "FromPoint". No standalone definition needed. |
| `FromPoint` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Frontmatter lint` | docs | quality-gates.md, relationships.md, technology-stack.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Frontmatter Rules` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Frontmatter Value` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "FrontmatterValue". No standalone definition needed. |
| `FrontmatterValue` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Full Form` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `full runnable form` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Functional Requirements` | docs | artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Gap Inventory` | docs | domain-glossary.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Gate Criteria` | docs | artifact-schemas.md, decisions.md, domain-glossary.md, pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Gate Criterion` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Gate Escalations` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Gate Note` | docs | STATE.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Gated Phase Advancement` | docs | architecture.md, domain-glossary.md, relationships.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Generated` | docs | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Generated and Temporary Files` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Generated-Files Registry` | docs | artifact-schemas.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Generator Self` | docs | infrastructure.md, relationships.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Git Bash` | history | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Git Guardian` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "GitGuardian". No standalone definition needed. |
| `Git Hub` | docs,history | (not found in KB body text) | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `GitGuardian` | docs | STATE.md, infrastructure.md, integration-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `GitHub` | docs,history | INDEX.md, STATE.md, architecture.md, artifact-schemas.md, … | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `Gotchas` | docs | INDEX.md, architecture.md, authoring-conventions.md, module-map.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Grade` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Grade". |
| `Grade Calculation` | docs | quality-gates.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Grade Is Computed` | docs | authoring-conventions.md, decisions.md, domain-glossary.md, quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Grade Thresholds` | docs | INDEX.md, quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Graph Model` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "GraphModel". No standalone definition needed. |
| `Graph View` | history | INDEX.md, relationships.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "GraphView". No standalone definition needed. |
| `Graphics Context` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "GraphicsContext". No standalone definition needed. |
| `GraphicsContext` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `GraphModel` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `GraphView` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Group Centres` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "GroupCentres". No standalone definition needed. |
| `GroupCentres` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Grouping Divergence` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "GroupingDivergence". No standalone definition needed. |
| `GroupingDivergence` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `hatchling` | docs | infrastructure.md, relationships.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Have Property` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "HaveProperty". No standalone definition needed. |
| `HaveProperty` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `heavy gates are master-only` | docs | INDEX.md, tech-debt.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Hidden Selection` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "HiddenSelection". No standalone definition needed. |
| `HiddenSelection` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `High-Churn Modules` | docs | module-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Host Exe` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "HostExe". No standalone definition needed. |
| `HostExe` | history | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `How AID Is Tested` | docs | relationships.md, test-landscape.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `How Artifacts Relate` | docs | artifact-schemas.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `How the Pipeline Works` | docs | pipeline-contracts.md, relationships.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Hub Actions` | docs | INDEX.md, STATE.md, domain-glossary.md, infrastructure.md, … | not defined | **dismiss** | GitHub platform term; not AID-coined. |
| `Hub Copilot` | docs | capability-inventory.md, domain-glossary.md, integration-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Hub Issue` | docs | infrastructure.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Hub Pages` | docs | infrastructure.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Hub Release` | docs,history | capability-inventory.md, domain-glossary.md, infrastructure.md, integration-map.md, … | not defined | **dismiss** | GitHub platform term; not AID-coined. |
| `Hub Releases` | docs,history | domain-glossary.md, infrastructure.md, integration-map.md, technology-stack.md | not defined | **dismiss** | GitHub platform term; not AID-coined. |
| `Human Grade` | docs | STATE.md, artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `human-gated phase advancement` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine (Human-Gated Phase Advancement). |
| `I cannot tell` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Impact Map` | docs,history | release-tracking.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `In Progress` | docs,history | artifact-schemas.md, domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "In Progress". |
| `In Review` | docs,history | artifact-schemas.md, capability-inventory.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `incomplete` | docs | decisions.md, pipeline-contracts.md, relationships.md, tech-debt.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Index` | docs | (not found in KB body text) | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `infrastructure` | docs | INDEX.md, README.md, STATE.md, artifact-schemas.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Install` | docs | INDEX.md, README.md, STATE.md, architecture.md, … | not defined | **dismiss** | Standard software development term; not AID-coined. |
| `Install Bootstrap` | docs | INDEX.md, infrastructure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Install Bootstrap and Manifests` | docs | infrastructure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Install channel` | docs | domain-glossary.md, integration-map.md, release-tracking.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Install Manifest` | docs | architecture.md, artifact-schemas.md, authoring-conventions.md, capability-inventory.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Install Mechanics` | docs | domain-glossary.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Install Profiles` | docs | capability-inventory.md, integration-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Installer Tests` | docs | integration-map.md, module-map.md, project-structure.md, relationships.md, technology-stack.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Integrated Development` | docs | README.md, capability-inventory.md, domain-glossary.md, project-structure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Integrated Software Development` | docs | architecture.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Integration Health Risks` | docs | integration-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Integration Map` | docs | integration-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `integrations` | docs | INDEX.md, architecture.md, capability-inventory.md, domain-glossary.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Interview State` | docs | artifact-schemas.md, domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Invariants` | docs | INDEX.md, architecture.md, artifact-schemas.md, authoring-conventions.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Iron Man` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Is Linux` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "IsLinux". No standalone definition needed. |
| `Is Mac` | docs | tech-debt.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "IsMac". No standalone definition needed. |
| `Is Polyglot` | docs | coding-standards.md, project-structure.md, relationships.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Is Tested` | docs | relationships.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Is Windows` | docs | coding-standards.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "IsWindows". No standalone definition needed. |
| `IsLinux` | docs | coding-standards.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `IsMac` | docs | coding-standards.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Issue List` | docs | artifact-schemas.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `IsWindows` | docs | coding-standards.md, decisions.md, tech-debt.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Its Deferred` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Java Script` | docs,history | (not found in KB body text) | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `JavaScript` | docs,history | INDEX.md, coding-standards.md, project-structure.md, relationships.md, tech-debt.md, technology-stack.md | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `KB Document Layout` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `KB Documents Status` | docs | STATE.md, artifact-schemas.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Key Constraints` | docs | module-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Key Dependencies` | docs | relationships.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Key Files` | docs | module-map.md, project-structure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `key non-dependency` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `keydown` | docs | tech-debt.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Knowledge Base` | docs,history | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Knowledge Base". |
| `Knowledge Base Index` | docs | INDEX.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Knowledge Base Maintenance` | docs | architecture.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Knowledge Before Specification` | docs | decisions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Knowledge Relationship Graph` | history | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Knowledge Summary Status` | docs | STATE.md, artifact-schemas.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Known Issues` | docs | pipeline-contracts.md, relationships.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Known Test Gaps` | docs | relationships.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Label From Workers` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "LabelFromWorkers". No standalone definition needed. |
| `LabelFromWorkers` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Language Breakdown` | docs | artifact-schemas.md, project-structure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Largest Source Files` | docs | module-map.md, project-structure.md, relationships.md, tech-debt.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Last Reviewed` | docs | STATE.md, artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Last Run` | docs | STATE.md, pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Last Summary` | docs | STATE.md, artifact-schemas.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Last Updated` | docs | architecture.md, decisions.md, domain-glossary.md, external-sources.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Leaf Base` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "LeafBase". No standalone definition needed. |
| `LeafBase` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Lens State` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "LensState". No standalone definition needed. |
| `LensState` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Level Directory Purposes` | docs,history | INDEX.md, project-structure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `LICENSE` | docs | project-structure.md, relationships.md | not defined | **define** | Shouted code / state name. Needs a legend or Lexicon entry so readers know what it means. |
| `Lifecycle Badge` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "Lifecycle Badge". |
| `Lifecycle History` | docs,history | artifact-schemas.md, domain-glossary.md, quality-gates.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `LifecycleBadge` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "LifecycleBadge". |
| `lightweight version` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Line Interface` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Link Card` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "LinkCard". No standalone definition needed. |
| `Link Cards` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "LinkCards". No standalone definition needed. |
| `LinkCard` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `LinkCards` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `lint` | docs | INDEX.md, STATE.md, artifact-schemas.md, authoring-conventions.md, … | not defined | **dismiss** | Standard software development term; not AID-coined. |
| `Lint Commands` | docs | relationships.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Linux Trash` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Lite Path` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Lite Path". |
| `Load-Bearing Boundaries` | docs | architecture.md, relationships.md | not defined | **alias** | Section heading in architecture.md; the concept is "load-bearing" used as adjective. Alias or context of the replace disposition for "load-bearing". |
| `Local App Data` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "LocalAppData". No standalone definition needed. |
| `Local Bounds` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "LocalBounds". No standalone definition needed. |
| `Local Point` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "LocalPoint". No standalone definition needed. |
| `LocalAppData` | history | architecture.md, infrastructure.md, project-structure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `LocalBounds` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `LocalPoint` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Logging and Output` | docs | coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `lookup_list` | docs | authoring-conventions.md, coding-standards.md, relationships.md, tech-debt.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Loop 6` | docs | pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Loopback Re` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `loose PNGs` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Machine Grade` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Machine Model` | docs | architecture.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `make it loud` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Management mode` | docs | architecture.md, artifact-schemas.md, decisions.md, domain-glossary.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Management-mode branch` | docs | artifact-schemas.md, integration-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `MANIFEST` | docs | INDEX.md, STATE.md, architecture.md, artifact-schemas.md, … | not defined | **define** | Shouted code / state name. Needs a legend or Lexicon entry so readers know what it means. |
| `manifest-drift` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Mark Fixed` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Max Concurrent` | docs | (not found in KB body text) | defined — glossary table | **define** | Already defined — Lexicon table. |
| `Maybe Auto Fit` | docs,history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "MaybeAutoFit". No standalone definition needed. |
| `MaybeAutoFit` | docs,history | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `MCP and Playwright` | docs | integration-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Measured signals` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Mechanical Gates Run` | docs | quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Mermaid Cached` | docs | STATE.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `Mermaid Version` | docs | STATE.md, artifact-schemas.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `Migration Plan` | docs | artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Minimum Grade` | docs | STATE.md, quality-gates.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Minimum Viable Product` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Minimum-Grade Thresholds` | docs | INDEX.md, quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Missing Test Coverage` | docs | relationships.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Modal Explicit Render` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ModalExplicitRender". No standalone definition needed. |
| `Modal State` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ModalState". No standalone definition needed. |
| `ModalExplicitRender` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ModalState` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Model Context Protocol` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Model For Header` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ModelForHeader". No standalone definition needed. |
| `Model Tier Detailed` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ModelTierDetailed". No standalone definition needed. |
| `Model Tier Simple` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ModelTierSimple". No standalone definition needed. |
| `ModelForHeader` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ModelTierDetailed` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ModelTierSimple` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Module Inventory` | docs | module-map.md, relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Module Map` | docs | module-map.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Most Bash` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Mount Shell` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "MountShell". No standalone definition needed. |
| `Mount Unavailable` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "MountUnavailable". No standalone definition needed. |
| `MountShell` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `MountUnavailable` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Move Firing Table` | docs | capability-inventory.md, module-map.md, relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Mp Computer Status` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "MpComputerStatus". No standalone definition needed. |
| `MpComputerStatus` | docs | tech-debt.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Multi-tool distribution` | docs | INDEX.md, capability-inventory.md, relationships.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Mutation Observer` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "MutationObserver". No standalone definition needed. |
| `MutationObserver` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Name Set` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "NameSet". No standalone definition needed. |
| `named fault class` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `NameSet` | history | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Naming Conventions` | docs | coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `New Tools` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `No Args` | history | test-landscape.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "NoArgs". No standalone definition needed. |
| `No External Sources` | docs | external-sources.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `No Knowledge Base` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `no Mermaid engine` | docs | decisions.md, relationships.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `No Path` | docs | tech-debt.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "NoPath". No standalone definition needed. |
| `No Profile` | docs | domain-glossary.md, infrastructure.md | defined — glossary table | **define** | Already defined — glossary table entry "No Profile". |
| `No Skills Drift` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "NoSkillsDrift". No standalone definition needed. |
| `No-Mermaid-engine assertion` | docs | decisions.md, relationships.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `NoArgs` | history | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `node` | docs | (not found in KB body text) | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `Node Conventions` | docs | coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `node-version` | docs | relationships.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `NODE_VERSION_MAJOR -lt 20` | docs | relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `none` | docs | STATE.md, architecture.md, artifact-schemas.md, coding-standards.md, … | not defined | **dismiss** | Common English word or phrase; not a coined concept. |
| `None provided` | docs | STATE.md, external-sources.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `NoPath` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "NoPath". |
| `NoProfile` | docs | test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `NoSkillsDrift` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Not Applicable` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Notable Skill Reference Modules` | docs | module-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Now Accepted` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `npx playwright install chromium` | docs | relationships.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Num Py` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "NumPy". No standalone definition needed. |
| `NumPy` | docs | coding-standards.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `observation plane` | docs | capability-inventory.md, module-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Observed Inconsistencies` | docs | coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Of Skill` | history | pipeline-contracts.md, tech-debt.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "OfSkill". No standalone definition needed. |
| `OfSkill` | history | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `On Click` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "OnClick". No standalone definition needed. |
| `On Dbl Click` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "OnDblClick". No standalone definition needed. |
| `On Load` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "OnLoad". No standalone definition needed. |
| `On Notify` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "OnNotify". No standalone definition needed. |
| `On Pointer Move` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "OnPointerMove". No standalone definition needed. |
| `On Pointer Up` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "OnPointerUp". No standalone definition needed. |
| `On-demand skills` | docs | INDEX.md, STATE.md, capability-inventory.md, module-map.md, relationships.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `OnClick` | history | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `OnDblClick` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `One Work` | docs | artifact-schemas.md, domain-glossary.md, project-structure.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `OnLoad` | docs | tech-debt.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `OnNotify` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `OnPointerMove` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `OnPointerUp` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Open Item` | history | capability-inventory.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Open items` | docs | capability-inventory.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Open Knowledge Base` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Order For` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "OrderFor". No standalone definition needed. |
| `OrderFor` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Outdated` | docs | relationships.md, release-tracking.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Outdated Dependencies` | docs | relationships.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Output Contracts` | docs | pipeline-contracts.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Overall Grade` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `overrides` | docs | pipeline-contracts.md, relationships.md, release-tracking.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Oversized Modules` | docs | module-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Overview` | docs | STATE.md, integration-map.md, module-map.md, project-structure.md, relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Package Managers` | docs | infrastructure.md, relationships.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Package Registries` | docs | INDEX.md, integration-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Panel Node` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "PanelNode". No standalone definition needed. |
| `PanelNode` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Parallel Dispatch` | docs | artifact-schemas.md, domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Parity Foundation` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Pascal Case` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "PascalCase". No standalone definition needed. |
| `PascalCase` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `passed` | docs | STATE.md, coding-standards.md, domain-glossary.md, pipeline-contracts.md, release-tracking.md, tech-debt.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Path Gate` | docs | INDEX.md, quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `paths` | docs | architecture.md, artifact-schemas.md, authoring-conventions.md, coding-standards.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Payment Engine` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "PaymentEngine". No standalone definition needed. |
| `PaymentEngine` | docs | test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Per-Skill State Machines` | docs | INDEX.md, pipeline-contracts.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Phase Gate` | docs | INDEX.md, architecture.md, domain-glossary.md, pipeline-contracts.md, quality-gates.md, tech-debt.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Phase Input` | docs | pipeline-contracts.md, relationships.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Phase Pipeline` | docs | architecture.md, relationships.md, release-tracking.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Phase Transition` | docs | (not found in KB body text) | defined — glossary table | **define** | Already defined — Lexicon table. |
| `Pick a grade` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `pipeline` | docs | (not found in KB body text) | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Pipeline Contracts` | docs | pipeline-contracts.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Pipeline Diagram` | docs | domain-glossary.md, project-structure.md, release-tracking.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "PipelineDiagram". No standalone definition needed. |
| `Pipeline Finish` | history | (not found in KB body text) | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Pipeline Lifecycle` | docs | artifact-schemas.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Pipeline Run` | docs | domain-glossary.md, project-structure.md, relationships.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Pipeline State` | docs,history | (not found in KB body text) | defined — glossary table | **define** | Already defined — Lexicon — Pipeline Run-State table. |
| `Pipeline Status` | docs | infrastructure.md, release-tracking.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Pipeline Works` | docs | pipeline-contracts.md, relationships.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `PipelineDiagram` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — Lexicon — UI Components table. |
| `PipelineState` | history | (not found in KB body text) | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Playwright MCP` | docs | STATE.md, domain-glossary.md, infrastructure.md, integration-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `PM-TOOL` | docs | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Policy Bypass` | docs | test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `polyglot by design` | docs | domain-glossary.md, project-structure.md, relationships.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Polyglot Parity Obligation` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine (Polyglot Parity Obligation). |
| `Posix Arg` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "PosixArg". No standalone definition needed. |
| `PosixArg` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Power Shell` | docs,history | (not found in KB body text) | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `PowerShell` | docs,history | INDEX.md, STATE.md, architecture.md, artifact-schemas.md, … | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `PowerShell Conventions` | docs | coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Prefer Trusted Publishing` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `prepack` | docs | architecture.md, infrastructure.md, integration-map.md, relationships.md, technology-stack.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Private Python` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Problem Statement` | docs | artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Process Architecture` | docs | INDEX.md, architecture.md, relationships.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `product` | docs | INDEX.md, README.md, STATE.md, architecture.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Profile` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Profile". |
| `Profile Confidence` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Profile Render` | docs | INDEX.md, STATE.md, decisions.md, domain-glossary.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Profile Source` | docs | STATE.md, artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Program Data` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ProgramData". No standalone definition needed. |
| `Program Files` | docs | tech-debt.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ProgramData` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `project` | docs | INDEX.md, README.md, STATE.md, architecture.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Project Header Kb Button` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ProjectHeaderKbButton". No standalone definition needed. |
| `Project Header Path Row` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ProjectHeaderPathRow". No standalone definition needed. |
| `Project Management Tooling` | docs,history | infrastructure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Project Structure` | docs | project-structure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Project Type` | docs | architecture.md, authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ProjectHeaderKbButton` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ProjectHeaderPathRow` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `projects` | docs | decisions.md, infrastructure.md, pipeline-contracts.md, project-structure.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Prone Content` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `proper metric` | docs | authoring-conventions.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Property Not Found Exception` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "PropertyNotFoundException". No standalone definition needed. |
| `PropertyNotFoundException` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Prose Over Scripts` | docs | authoring-conventions.md, decisions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Prune Dirs` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "PruneDirs". No standalone definition needed. |
| `PruneDirs` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Pure Agile` | docs | decisions.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Pwsh Exe` | history | release-tracking.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "PwshExe". No standalone definition needed. |
| `PwshExe` | history | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Python Conventions` | docs | coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Quality Gates` | docs | artifact-schemas.md, pipeline-contracts.md, quality-gates.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Quick Check` | history | artifact-schemas.md, domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Quick Check Findings` | docs,history | (not found in KB body text) | defined — glossary table | **define** | Already defined — glossary table entry "Quick Check Findings". |
| `Quick Start` | docs,history | architecture.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `RAG by convention` | docs | architecture.md, decisions.md, domain-glossary.md, relationships.md | defined — glossary table | **define** | Already defined — Lexicon table (RAG by convention). |
| `Ranked Candidates` | docs | (not found in KB body text) | defined — glossary table | **define** | Already defined — Lexicon — KB Authoring table (Ranked Candidates). |
| `recipe` | docs | STATE.md, decisions.md, domain-glossary.md, pipeline-contracts.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Reconciliation Cycle` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ReconciliationCycle". No standalone definition needed. |
| `ReconciliationCycle` | docs | test-landscape.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Record Corrections` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Record Sink` | docs | architecture.md, domain-glossary.md, pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Refresh Reveal` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "RefreshReveal". No standalone definition needed. |
| `RefreshReveal` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Reg Exp` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "RegExp". No standalone definition needed. |
| `RegExp` | docs | tech-debt.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `region` | docs | artifact-schemas.md, authoring-conventions.md, coding-standards.md, domain-glossary.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Rejected alternatives` | docs | decisions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Release Commands` | docs | infrastructure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Release Tracking` | docs | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `render attempted` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `render plane` | docs | capability-inventory.md, module-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `repo` | docs | (not found in KB body text) | not defined | **dismiss** | Standard software development term; not AID-coined. |
| `Repo Info` | docs,history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "RepoInfo". No standalone definition needed. |
| `Repo Model` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "RepoModel". No standalone definition needed. |
| `RepoInfo` | docs,history | domain-glossary.md | defined — glossary table | **define** | Already defined — Lexicon — Dashboard Reader table (RepoInfo). |
| `RepoModel` | docs | domain-glossary.md, integration-map.md | defined — glossary table | **define** | Already defined — glossary table entry "RepoModel". |
| `Report Form` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ReportForm". No standalone definition needed. |
| `ReportForm` | docs | relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `repos` | docs | INDEX.md, STATE.md, architecture.md, capability-inventory.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Repository Overview` | docs | project-structure.md, relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Resolved Findings` | docs | pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Resolved Items Leave No` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Restoring Dispatch` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Review History` | docs,history | STATE.md, artifact-schemas.md, relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Review record format` | docs | pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Reviewer Ledger Convention` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Reviewer Tier` | docs | architecture.md, artifact-schemas.md, decisions.md, relationships.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Revision History` | docs,history | INDEX.md, README.md, decisions.md, pipeline-contracts.md, relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Root Agent File` | docs | authoring-conventions.md, coding-standards.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "RootAgentFile". No standalone definition needed. |
| `Root From Aid Dir` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "RootFromAidDir". No standalone definition needed. |
| `root_agent_files` | docs | artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `RootAgentFile` | docs | authoring-conventions.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `RootFromAidDir` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `Row Records` | history | tech-debt.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "RowRecords". No standalone definition needed. |
| `RowRecords` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `run all tests` | docs | test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Run Cadence` | docs,history | relationships.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Running Confirm` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `runtime prerequisite` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Scope Plan` | docs,history | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Script Analyzer` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ScriptAnalyzer". No standalone definition needed. |
| `Script Modules` | docs | module-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Script Modules by Area` | docs | module-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `ScriptAnalyzer` | docs | coding-standards.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Seasoned-Analyst Engine` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine (Seasoned-Analyst Engine). |
| `Secret Ref` | docs | artifact-schemas.md, integration-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Section Description` | history | (not found in KB body text) | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Security Conventions` | docs | INDEX.md, coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Security Observations` | docs | INDEX.md, infrastructure.md, relationships.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Security Protocol` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SecurityProtocol". No standalone definition needed. |
| `Security Protocol Type` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SecurityProtocolType". No standalone definition needed. |
| `Security Specs` | docs | artifact-schemas.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `SecurityProtocol` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `SecurityProtocolType` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Seed Authoring` | docs | artifact-schemas.md, domain-glossary.md, module-map.md, release-tracking.md | defined — glossary table | **define** | Already defined — glossary table entry "Seed Authoring". |
| `Sem Ver` | docs,history | (not found in KB body text) | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `SemVer` | docs,history | decisions.md, infrastructure.md, release-tracking.md | not defined | **dismiss** | Widely-known versioning convention (Semantic Versioning); not AID-coined. |
| `Service Point Manager` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ServicePointManager". No standalone definition needed. |
| `ServicePointManager` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Set Count` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Set Derivation` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Set Source` | docs | STATE.md, integration-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Settled decisions` | docs | decisions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Settlement Batch` | docs | test-landscape.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SettlementBatch". No standalone definition needed. |
| `Seven Link` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `sha256` | docs | architecture.md, artifact-schemas.md, coding-standards.md, decisions.md, … | defined — glossary table | **define** | Already defined — glossary table entry "sha256". |
| `Shared Helpers` | history | test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Shell Conventions` | docs | coding-standards.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Shipped Power` | docs | coding-standards.md, decisions.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `shortcut` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Shortcut". |
| `Shortcut Catalog` | history | architecture.md, capability-inventory.md, module-map.md, pipeline-contracts.md, project-structure.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ShortcutCatalog". No standalone definition needed. |
| `Shortcut Engine` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Shortcut Engine". |
| `Shortcut families` | docs | capability-inventory.md, domain-glossary.md, relationships.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Shortcut Families Section` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ShortcutFamiliesSection". No standalone definition needed. |
| `ShortcutCatalog` | history | (not found in KB body text) | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `ShortcutFamiliesSection` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Sibling Parent` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SiblingParent". No standalone definition needed. |
| `SiblingParent` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Signature Exception` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Size Control` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SizeControl". No standalone definition needed. |
| `SizeControl` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Skill Count` | history | STATE.md, architecture.md, capability-inventory.md, module-map.md, release-tracking.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SkillCount". No standalone definition needed. |
| `Skill Counts` | history | STATE.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SkillCounts". No standalone definition needed. |
| `Skill Explorer` | docs,history | STATE.md, module-map.md, relationships.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Skill Index` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SkillIndex". No standalone definition needed. |
| `Skill Inventory` | docs,history | architecture.md, pipeline-contracts.md, relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Skill Record` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SkillRecord". No standalone definition needed. |
| `Skill State` | docs | INDEX.md, architecture.md, authoring-conventions.md, module-map.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Skill State Machines` | docs | INDEX.md, architecture.md, module-map.md, pipeline-contracts.md, relationships.md, tech-debt.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Skill State-Machine Model` | docs | architecture.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Skill Structural Shapes` | docs,history | module-map.md, relationships.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `SkillCount` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `SkillCounts` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `SkillIndex` | history | (not found in KB body text) | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `SkillRecord` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Skills Page` | history | module-map.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SkillsPage". No standalone definition needed. |
| `SkillsPage` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `slot` | docs | decisions.md, pipeline-contracts.md, release-tracking.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `slow` | docs | INDEX.md, decisions.md, relationships.md, tech-debt.md, test-landscape.md | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Sort Of` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SortOf". No standalone definition needed. |
| `SortOf` | history | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Source Control` | docs | INDEX.md, infrastructure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Source Id` | docs,history | relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Source Kind` | docs | relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Source Name` | docs | relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Source Render` | docs | INDEX.md, decisions.md, domain-glossary.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Sourceable Bash` | docs | module-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Sources` | docs | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Specific Domain Meanings` | docs | domain-glossary.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Spread For` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SpreadFor". No standalone definition needed. |
| `SpreadFor` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Stale Work Notice` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "StaleWorkNotice". No standalone definition needed. |
| `StaleWorkNotice` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Star Points` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "StarPoints". No standalone definition needed. |
| `StarPoints` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Start Line` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "StartLine". No standalone definition needed. |
| `StartLine` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `State Detection` | docs,history | domain-glossary.md, pipeline-contracts.md | defined — glossary table | **define** | Already defined — glossary table entry "State Detection". |
| `State Machine` | docs,history | INDEX.md, architecture.md, authoring-conventions.md, capability-inventory.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `State-File Hierarchy` | docs | artifact-schemas.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `status` | docs | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Step Zero` | history | (not found in KB body text) | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `Sticky Top` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "StickyTop". No standalone definition needed. |
| `StickyTop` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Still Load` | docs | decisions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Still Load-Bearing` | docs | decisions.md, relationships.md | not defined | **dismiss** | Section heading fragment from relationships.md; not a standalone concept. |
| `Stop Requested` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "StopRequested". No standalone definition needed. |
| `Stop Requested Pill` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "StopRequestedPill". No standalone definition needed. |
| `StopRequested` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `StopRequestedPill` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Strict Mode` | docs | authoring-conventions.md, coding-standards.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "StrictMode". No standalone definition needed. |
| `StrictMode` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Suggest-only router` | docs | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Suite Authoring` | docs,history | relationships.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `suite-presence per subsystem` | docs | decisions.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Summarization History` | docs | STATE.md, artifact-schemas.md, pipeline-contracts.md, relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Summary` | docs | INDEX.md, README.md, STATE.md, architecture.md, … | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Summary Stage` | docs | (not found in KB body text) | defined — glossary table | **define** | Already defined — glossary table entry "Summary Stage". |
| `Summary Table` | docs | decisions.md, relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Suppressed Hidden Selection` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "SuppressedHiddenSelection". No standalone definition needed. |
| `SuppressedHiddenSelection` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `SVG present` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Table Fn` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TableFn". No standalone definition needed. |
| `TableFn` | history | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Target Directory` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TargetDirectory". No standalone definition needed. |
| `Target For` | history | artifact-schemas.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TargetFor". No standalone definition needed. |
| `Target Id` | docs | relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Target Kind` | docs | relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Target Name` | docs | relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `TargetDirectory` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "TargetDirectory". |
| `Targeted Interview` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `TargetFor` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Task` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Task". |
| `Task Chip` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TaskChip". No standalone definition needed. |
| `Task Detail` | docs | (not found in KB body text) | defined — glossary table | **define** | Already defined — glossary table entry "Task Detail". |
| `Task Model` | docs,history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TaskModel". No standalone definition needed. |
| `Task State` | docs | artifact-schemas.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Task Status` | docs,history | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine + Lexicon table. |
| `Task Stop` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Task Stop Resume Control` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TaskStopResumeControl". No standalone definition needed. |
| `Task Type` | docs | architecture.md, artifact-schemas.md, capability-inventory.md, domain-glossary.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Task View` | history | domain-glossary.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TaskView". No standalone definition needed. |
| `TaskChip` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `TaskModel` | docs,history | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Tasks Full` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TasksFull". No standalone definition needed. |
| `Tasks State` | docs,history | (not found in KB body text) | defined — glossary table | **define** | Already defined — glossary table entry "Tasks State". |
| `Tasks Status` | docs | infrastructure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `TasksFull` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `TaskStatus` | docs,history | (not found in KB body text) | defined — glossary table | **define** | Already defined — Lexicon table (TaskStatus). |
| `TaskStopResumeControl` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `TaskView` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Tech Debt` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Technical Specification` | docs | artifact-schemas.md, domain-glossary.md, pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Technology Stack` | docs | artifact-schemas.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Temporary Files` | docs | authoring-conventions.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Term Name` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "Term Name". |
| `Test Aid Cli Path Arg` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TestAidCliPathArg". No standalone definition needed. |
| `Test Commands` | docs | INDEX.md, relationships.md, technology-stack.md, test-landscape.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Test Connector Form Type Dependent Fields` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TestConnectorFormTypeDependentFields". No standalone definition needed. |
| `Test Data Strategy` | docs | relationships.md, test-landscape.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Test Directories` | docs | project-structure.md, relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Test Framework Inventory` | docs | relationships.md, test-landscape.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Test Kb Button` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TestKbButton". No standalone definition needed. |
| `Test Landscape` | docs | test-landscape.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Test No Redundant Kb Button` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TestNoRedundantKbButton". No standalone definition needed. |
| `Test Op Dispatch Live` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TestOpDispatchLive". No standalone definition needed. |
| `Test Twin Dispatch Parity` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TestTwinDispatchParity". No standalone definition needed. |
| `TestAidCliPathArg` | history | (not found in KB body text) | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `TestConnectorFormTypeDependentFields` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `TestKbButton` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `TestNoRedundantKbButton` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `TestOpDispatchLive` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `TestTwinDispatchParity` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `That Is` | docs | STATE.md, authoring-conventions.md, decisions.md, domain-glossary.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Add` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Agent` | docs | INDEX.md, architecture.md, authoring-conventions.md, capability-inventory.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `the AID dashboard component` | docs | domain-glossary.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `The Astro` | docs | architecture.md, infrastructure.md, integration-map.md, module-map.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Bracket` | history | pipeline-contracts.md, quality-gates.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Build` | docs | architecture.md, capability-inventory.md, domain-glossary.md, infrastructure.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The build pipeline` | docs | architecture.md, domain-glossary.md, integration-map.md, relationships.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `The Canonical Helper Suites` | docs | project-structure.md, relationships.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Codex` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Conformance Check` | docs | STATE.md, capability-inventory.md, domain-glossary.md, pipeline-contracts.md, quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Conformance Lane` | docs | quality-gates.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Dashboard Server` | docs | INDEX.md, infrastructure.md, integration-map.md, project-structure.md, relationships.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Delivery Gate` | docs,history | INDEX.md, artifact-schemas.md, decisions.md, domain-glossary.md, quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Describe` | docs | capability-inventory.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Description` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Directory Tree` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Discover Review Panel` | docs | INDEX.md, quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Documentation Site` | docs | infrastructure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The dogfood install` | docs | domain-glossary.md, project-structure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Eleven Loops` | docs | architecture.md, decisions.md, pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Envelope Template` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Execution` | history | domain-glossary.md, pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Five Profiles` | docs | architecture.md, domain-glossary.md, integration-map.md, pipeline-contracts.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Full Path` | docs | architecture.md, artifact-schemas.md, capability-inventory.md, decisions.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Grade Scale` | docs | INDEX.md, quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Grading Gate Contract` | docs | pipeline-contracts.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Knowledge Base` | docs,history | INDEX.md, STATE.md, architecture.md, capability-inventory.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Lite Path` | docs | artifact-schemas.md, decisions.md, domain-glossary.md, pipeline-contracts.md, quality-gates.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Monitor` | docs | pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Node` | docs | artifact-schemas.md, coding-standards.md, domain-glossary.md, integration-map.md, module-map.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The On` | docs | INDEX.md, STATE.md, architecture.md, authoring-conventions.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The On-Disk Work Hierarchy` | docs | INDEX.md, pipeline-contracts.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Per` | docs | INDEX.md, README.md, architecture.md, artifact-schemas.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Phases` | docs | architecture.md, domain-glossary.md, pipeline-contracts.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `The Pipeline` | docs | INDEX.md, architecture.md, artifact-schemas.md, authoring-conventions.md, … | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `The Playwright` | docs | decisions.md, infrastructure.md, integration-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Power` | docs | architecture.md, decisions.md, domain-glossary.md, integration-map.md, project-structure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Py` | docs | coding-standards.md, integration-map.md, module-map.md, technology-stack.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Python` | docs,history | module-map.md, technology-stack.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Record Corrections` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Reference` | history | test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Release Pipeline` | docs | infrastructure.md, relationships.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `The repo dogfoods itself` | docs | architecture.md, project-structure.md, relationships.md | not defined | **alias** | Prose description of the Dual-Face Dogfood Repository concept; not a coined term. |
| `The Reviewer Ledger` | docs | INDEX.md, module-map.md, quality-gates.md, relationships.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `the scan completed` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Sem` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Shortcut` | docs | INDEX.md, artifact-schemas.md, capability-inventory.md, decisions.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The shortcut engine` | docs | artifact-schemas.md, capability-inventory.md, decisions.md, domain-glossary.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Six` | docs | INDEX.md, architecture.md, pipeline-contracts.md, relationships.md, tech-debt.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Skill Explorer` | docs | module-map.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Source` | history | INDEX.md, architecture.md, authoring-conventions.md, capability-inventory.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Step` | history | tech-debt.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `The Two Faces` | docs | architecture.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Two Layers` | docs | quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The two-tier review design` | docs | domain-glossary.md, pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The universal loop` | docs | pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Web` | history | architecture.md, module-map.md, project-structure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `The Win` | docs | module-map.md, project-structure.md, relationships.md, release-tracking.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `This Knowledge Base` | docs | README.md, architecture.md, project-structure.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `This Scale` | docs | decisions.md, quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Three Doors In` | docs | architecture.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Tier Mapping` | docs | relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Tier Mapping per Profile` | docs | relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `To File` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ToFile". No standalone definition needed. |
| `ToFile` | history | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Tool Harnesses` | docs | INDEX.md, integration-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `toolkit plane` | docs | capability-inventory.md, module-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `tools` | docs | INDEX.md, architecture.md, artifact-schemas.md, capability-inventory.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Top-Level Directory Purposes` | docs | INDEX.md, project-structure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Total suites` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Track` | docs | INDEX.md, README.md, STATE.md, architecture.md, … | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Transition To Unavailable` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TransitionToUnavailable". No standalone definition needed. |
| `TransitionToUnavailable` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Triage` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Triage". |
| `Trim Segment` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TrimSegment". No standalone definition needed. |
| `TrimSegment` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Trusted Publishing` | docs | infrastructure.md, tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Type Error` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "TypeError". No standalone definition needed. |
| `Type Script` | docs | (not found in KB body text) | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `Typed Artifact Contracts` | docs | INDEX.md, pipeline-contracts.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `TypeError` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `typescript` | docs | decisions.md, project-structure.md, relationships.md, technology-stack.md, test-landscape.md | not defined | **dismiss** | Widely-known product/proper name; not AID-coined. |
| `Ubiquitous Language` | docs | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `uncovered` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Unique Term` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "Unique Term". |
| `Unlisted Nodes` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "UnlistedNodes". No standalone definition needed. |
| `UnlistedNodes` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Unreleased` | docs | INDEX.md, STATE.md, relationships.md, release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Unresolvable Outcome` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "UnresolvableOutcome". No standalone definition needed. |
| `UnresolvableOutcome` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Unusual Structure Notes` | docs,history | project-structure.md, relationships.md | not defined | **dismiss** | Document section heading or structural label; not a coined concept. |
| `Update Tools` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Use Objective` | docs | INDEX.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `User Approved` | docs | STATE.md, artifact-schemas.md, domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "User Approved". |
| `User Stories` | docs | artifact-schemas.md, pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Validation` | docs | INDEX.md, STATE.md, artifact-schemas.md, coding-standards.md, … | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Validation Commands` | docs | quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Vendor Pipeline` | docs | domain-glossary.md, relationships.md | not defined | **replace** | Generic process vocabulary. Replace with a more specific plain-English description. |
| `version` | docs | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `Version Badge` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "VersionBadge". No standalone definition needed. |
| `Version Concerns` | docs | relationships.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Version Control` | docs | INDEX.md, integration-map.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Version Latest` | docs | coding-standards.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `VersionBadge` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — Lexicon — UI Components table. |
| `Versioning and Version-Sync` | docs | infrastructure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `View Model` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ViewModel". No standalone definition needed. |
| `ViewModel` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Viewport For` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ViewportFor". No standalone definition needed. |
| `ViewportFor` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Viewports Agree` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "ViewportsAgree". No standalone definition needed. |
| `ViewportsAgree` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Voice Over` | docs | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "VoiceOver". No standalone definition needed. |
| `VoiceOver` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Was Fixed` | docs | quality-gates.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `waves` | docs | (not found in KB body text) | not defined | **dismiss** | Common English or programming term; not a coined concept. |
| `what ships when` | docs | domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `What This Project Is` | docs | project-structure.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `What You Do` | docs | module-map.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Where They Run` | docs | relationships.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `which door` | docs | decisions.md, domain-glossary.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Why AID` | docs | INDEX.md, decisions.md, project-structure.md, relationships.md, technology-stack.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `Why AID Is Polyglot` | docs | relationships.md, technology-stack.md | not defined | **dismiss** | AID-prefixed technical term; defined in context or documented as script/module name. |
| `Why This Scale` | docs | quality-gates.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Windows Apps` | docs,history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "WindowsApps". No standalone definition needed. |
| `Windows Git Bash` | docs | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Windows Power` | docs,history | coding-standards.md, decisions.md, release-tracking.md, technology-stack.md, test-landscape.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `WindowsApps` | docs,history | release-tracking.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Work` | docs | (not found in KB body text) | defined — Concept Spine | **define** | Already defined — Concept Spine entry "Work". |
| `Work Artifacts` | docs | capability-inventory.md, domain-glossary.md, relationships.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Work By Id` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "Work By Id". |
| `Work Card` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "WorkCard". No standalone definition needed. |
| `Work Header` | history | (not found in KB body text) | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "WorkHeader". No standalone definition needed. |
| `Work Model` | docs | domain-glossary.md | not defined | **dismiss** | Harvest artifact: camelCase/PascalCase split of "WorkModel". No standalone definition needed. |
| `WorkById` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "WorkById". |
| `WorkCard` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `WorkHeader` | history | (not found in KB body text) | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `WorkModel` | docs | domain-glossary.md | defined — glossary table | **define** | Already defined — glossary table entry "WorkModel". |
| `Workspace structure` | docs | pipeline-contracts.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Writeback Status` | docs | STATE.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `you invoked me wrongly` | docs | tech-debt.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `Zero runtime dependency` | docs | decisions.md, relationships.md, technology-stack.md | not defined | **dismiss** | Section heading, structural label, or common technical term. Not a coined AID concept requiring glossary coverage. |
| `load-bearing` | docs (supplemental; below harvest threshold) | architecture.md, artifact-schemas.md, authoring-conventions.md, coding-standards.md, … | not defined | **replace** | Construction-trade metaphor used as adjective meaning "fundamental" or "essential". Examples: "load-bearing term", "load-bearing boundaries", "load-bearing design". Replace with "fundamental", "essential", or "critical" throughout. Define-vs-replace trade-off: defining it would enshrine a metapho… |
| `render-drift` | docs (supplemental; filtered by denylist + spread=1) | architecture.md, infrastructure.md, integration-map.md, module-map.md, … | not defined | **define** | Specific CI gate and condition name: the state where profiles/ has diverged from canonical/ across a re-render pass. Not a generic term — it IS the gate/job name (test.yml job: render-drift). Cannot be replaced with plain words without renaming the CI job. Define-vs-replace trade-off: this term I… |
| `kind-sibling` | docs (supplemental; filtered by denylist + spread=1) | INDEX.md, module-map.md | not defined | **define** | One of four skill structural shapes: a skill that delegates to a sibling skill rather than the shortcut engine. Named in module-map.md §Skill Structural Shapes. Define-vs-replace trade-off: replacing with "sibling-delegating skill" or "skill that delegates to another skill" is verbose and loses t… |
| `thin doorway` | docs (supplemental; filtered by denylist + spread=1) | capability-inventory.md, decisions.md, pipeline-contracts.md | not defined | **alias** | Informal alias for the "Generated shortcut doorway" structural shape (module-map.md §Skill Structural Shapes table). Used in prose before the table introduced the canonical name. Define-vs-replace trade-off: replace "thin doorway" inline with "generated shortcut doorway" (the table's canonical na… |
| `fat pipeline` | docs (supplemental; filtered by denylist + spread=1) | INDEX.md, module-map.md | not defined | **define** | One of four skill structural shapes: a skill with a ## Dispatch table mapping states to references/state-*.md workers; no inline ## State: sections. Named in module-map.md §Skill Structural Shapes. Define-vs-replace trade-off: the term is already a coined name in the module-map table (full form: … |
| `hand-authored collapse` | docs (supplemental; filtered by denylist + spread=1) | INDEX.md, module-map.md | not defined | **define** | One of four skill structural shapes: a skill with six inline ## State: sections inside SKILL.md itself; self-contained, no delegation to reference files. Named in module-map.md §Skill Structural Shapes. Define-vs-replace trade-off: this is a coined taxonomy name and should be defined; replacing l… |
| `lockstep` | docs (supplemental; single word filtered by denylist) | architecture.md, infrastructure.md, integration-map.md, module-map.md, tech-debt.md | not defined | **replace** | Military/marching metaphor meaning "must change together, in coordinated fashion". Used in "the five install manifests must move in lockstep" (architecture.md), "install manifests stay in lockstep" (module-map.md), "a lockstep change" (integration-map.md). Define-vs-replace trade-off: defining it… |
| `HOME-pinning` | docs (supplemental; filtered by denylist + spread=1) | INDEX.md (tech-debt.md summary), tech-debt.md, test-landscape.md | not defined | **define** | Specific operational hazard: the migration-scan script defaults its root to $HOME, causing unintentionally wide filesystem scans if not guarded. Named in tech-debt.md and test-landscape.md §HOME-pinning hazard. Define-vs-replace trade-off: this term labels a concrete, named gotcha; a glossary ent… |
| `dogfood` | docs,code (supplemental; appears in harvest as compound forms) | architecture.md, decisions.md, domain-glossary.md, module-map.md, project-structure.md | defined — Concept Spine (Dual-Face Dogfood Repository) | **alias** | Short informal form of "Dual-Face Dogfood Repository" (Concept Spine). Used as verb ("the repo dogfoods itself") and adjective ("dogfood trees"). Acceptable in prose; add as **Aliases:** entry on the Dual-Face Dogfood Repository spine entry. Define-vs-replace trade-off: the full concept is alread… |
| `CONFIRMED` | docs (FR-4 shouted code) | architecture.md (first), artifact-schemas.md, authoring-conventions.md, coding-standards.md, … | not defined in glossary; used without legend | **define** | Evidence annotation tag: marks a factual claim as directly verified in a named source artifact. Used 225 times across 14 KB docs. First occurrence: architecture.md line 59. No legend exists in the KB today. Resolution route: add a named legend in authoring-conventions.md §Evidence Tags defining C… |
| `SYNTHESIS` | docs (FR-4 shouted code) | architecture.md (first occurrence line 73), technology-stack.md | not defined in glossary; used without legend | **define** | Evidence annotation tag: marks a KB conclusion synthesized across multiple sources, not traceable to a single citation. Used 4 times in 2 docs. First occurrence: architecture.md line 73. No legend exists today. Resolution route: define alongside CONFIRMED in authoring-conventions.md §Evidence Tag… |
| `ELICIT / ELICIT E1/E2` | docs (FR-4 shouted code) | architecture.md (first), artifact-schemas.md, capability-inventory.md, coding-standards.md, … | described in architecture.md; no glossary legend | **define** | State name in aid-discover skill state machine (ELICIT → GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE). E1/E2 are sub-steps within ELICIT (E1: external-documentation population signal; E2: connector registry authoring). First occurrence as bare code: architecture.md line 293. A partial leg… |
| `APPROVAL-HALT` | docs (FR-4 shouted code) | architecture.md (first), capability-inventory.md, decisions.md, domain-glossary.md, … | described in architecture.md, quality-gates.md; no dedica… | **define** | Terminal state of the shortcut engine state machine (INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT): pauses execution to require human approval before continuing. First occurrence: architecture.md line 205. Described inline in architecture.md and quality-gates.md but not in gloss… |
| `S1-S5` | docs (FR-4 shouted code) | INDEX.md (first), relationships.md, test-landscape.md | defined in test-landscape.md §Suite Authoring (S1-S5) wit… | **define** | Suite authoring convention codes (S1=invoke-once per input, S2=memory-pass assertions, S3=mutation flag, S4=no coverage trade, S5=copy-mutate). First occurrence: test-landscape.md line 443. A legend (named section § S1-S5) already exists in test-landscape.md. Resolution route: add S1-S5 to domain… |
| `T1-T6` | docs (FR-4 shouted code) | artifact-schemas.md (T3 first), INDEX.md, relationships.md, test-landscape.md | defined in test-landscape.md §Run Cadence (T1-T6) with le… | **define** | Run cadence convention codes (T1=author-first, T2=spawn-free verification, T3=milestone run, T4=full-deliverable run, T5=ceiling declaration, T6=group-filter debug). First occurrence as individual code: artifact-schemas.md (T3). Full legend: test-landscape.md §T1-T6 (line 495). Resolution route: … |
| `P1 / P3 / P5 / P7 / P9 / P10 (kb-authoring principles)` | docs (FR-4 shouted code) | authoring-conventions.md (first and primary), coding-standards.md, module-map.md, relationships.md, … | defined in authoring-conventions.md body; no glossary cro… | **define** | Numbered authoring principle codes: P1=no-navigational-content, P3=review-fix-separate, P5=refresh-last-in-FIX, P7=scratch-under-.aid/.temp, P9=current-state-only, P10=top-to-bottom-layout. First occurrence of P1: authoring-conventions.md line 135. Full legend is embedded in authoring-conventions… |
| `C0-C9 (concern/dimension IDs)` | docs (FR-4 shouted code) | All 17 KB docs (frontmatter tags field) | described in authoring-conventions.md; used as frontmatte… | **define** | Knowledge-base concern/dimension IDs used as frontmatter tags to anchor docs to the Concept Spine: C0=technology-stack, C1=architecture, C2=modules+integrations, C3=conventions, C4=glossary, C5=schemas, C6=testing+gates, C7=tech-debt, C8=infrastructure, C9=capabilities. First usage: architecture.… |
| `GENERATE / REVIEW / Q-AND-A / FIX / APPROVAL / DONE (aid-discover states)` | docs (FR-4 additional shouted codes) | architecture.md (first), pipeline-contracts.md | described inline in architecture.md; no glossary entry | **define** | State names in aid-discover state machine. First occurrence: architecture.md line 293 ("Discover runs ELICIT → GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE"). Resolution route: add state machine state names (ELICIT, GENERATE, REVIEW, Q-AND-A, FIX, APPROVAL, DONE, DESCRIBE-SEED, COMPLETION,… |
| `INTAKE / CAPTURE / SPEC / PLAN / DETAIL / GATE / APPROVAL-HALT (shortcut engine states)` | docs (FR-4 additional shouted codes) | architecture.md (first), capability-inventory.md, decisions.md, domain-glossary.md, … | described in architecture.md; no glossary entry for the s… | **define** | State sequence of the shortcut engine (canonical/aid/templates/shortcut-engine.md). First occurrence: architecture.md line 205. APPROVAL-HALT is covered separately above. Resolution route: add shortcut engine state sequence to Lexicon — Pipeline Run-State with cross-reference to shortcut-engine.m… |
| `VERIFY (deterministic)` | docs (FR-4 additional shouted code) | architecture.md (first), artifact-schemas.md, infrastructure.md, integration-map.md | described in architecture.md line 133; no Lexicon entry | **define** | Named CI gate: re-renders all five profiles into scratch, then byte-compares against committed profiles/. Fails on any difference. First occurrence: architecture.md line 133. Resolution route: add to Lexicon — Build, Render and Install Mechanics. Closely related to render-drift (the CI job name).… |
| `W-series / W1-N / W5-N (tech-debt IDs)` | docs (additional shouted codes found in sweep) | tech-debt.md (primary), STATE.md | used as row identifiers in tech-debt.md; no glossary entry | **dismiss** | Tech-debt item identifiers (W1-N = category-1 known issue, W5-N = category-5 debt item). Local identifier scheme defined implicitly by tech-debt.md table structure. No independent definition needed in glossary; table structure is self-documenting. Dismiss reason: locally-defined identifier series… |
| `D1-D26 (decision record IDs)` | docs (additional shouted codes found in sweep) | decisions.md (primary) | used as ADR identifiers in decisions.md; no glossary entry | **dismiss** | Decision record sequence numbers (D1=waterfall sequence, D2=knowledge-first, … D26=no-line-coverage). Local identifier scheme in decisions.md. Self-documenting via decisions.md table of contents. Dismiss reason: locally-defined numeric series; not a concept requiring cross-doc glossary coverage. |
| `SEC-1..4 (security invariants)` | docs (additional shouted codes found in sweep) | domain-glossary.md (defined), integration-map.md | defined — domain-glossary.md Abbreviations table (SEC-1..4) | **define** | Already defined — Abbreviations table entry "SEC-1..4" = security invariants for dashboard server (loopback-only bind SEC-1, read-only SEC-3, no LLM import SEC-4). No additional work needed. |
| `NFR-7` | docs (FR-4 shouted code / additional) | architecture.md, capability-inventory.md, decisions.md, domain-glossary.md, … | defined — Concept Spine (NFR-7 Suggested-Answer + Rationale) | **define** | Already defined — Concept Spine entry "NFR-7 Suggested-Answer + Rationale". The bare code NFR-7 is the shorthand; the full spine entry defines it. |
| `E1/E2 (ELICIT sub-steps)` | docs (FR-4 shouted code) | artifact-schemas.md (first), coding-standards.md, domain-glossary.md, module-map.md, pipeline-contracts.md | described in context; no standalone Abbreviations entry | **define** | ELICIT state sub-steps: E1=external-documentation population signal (writes ## External Documentation section in STATE.md), E2=connector-registry authoring (creates .aid/connectors/ descriptors). First occurrence: artifact-schemas.md line 420. Resolution route: include in the ELICIT/aid-discover … |
| `R0-R5 (reconcile steps)` | docs (additional shouted codes found in sweep) | artifact-schemas.md (first), coding-standards.md, module-map.md | described in context; no standalone Abbreviations entry | **define** | Connector reconciliation steps within ELICIT state: R0-R5 are the five reconcile sub-commands run by connector-registry scripts during connector add/update. First occurrence: artifact-schemas.md line 420 ("Steps R0-R5"). Resolution route: add to Lexicon — Connectors alongside E1/E2. Glossary plac… |
| `Q10 (open question ID)` | docs (additional shouted codes found in sweep) | architecture.md, artifact-schemas.md | referenced as STATE.md question identifier; no glossary e… | **dismiss** | State-file open-question sequence number (Q10 = "AID writes, wires, and manages no host tool's MCP configuration"). STATE.md question identifiers are ephemeral; Q10 is cited for traceability only. Dismiss reason: transient artifact identifier from a specific STATE.md; not an AID concept requiring… |
| `L4 (tech-debt effectiveness program)` | docs (additional shouted codes found in sweep) | decisions.md, tech-debt.md | referenced as tech-debt effectiveness category; no formal… | **dismiss** | Tech-debt effectiveness category identifier (L4 = test-effectiveness-gap program). Category identifiers in tech-debt.md are local numeric labels. Dismiss reason: locally-defined identifier; not an AID concept requiring glossary coverage. |