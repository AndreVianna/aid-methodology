# KB Migration

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-30) | /aid-interview |

## Source

- REQUIREMENTS.md §5.I (FR-30)
- REQUIREMENTS.md §2.9 (net impact / every phase loads the KB), NFR-7 (backward-compat during migration), D4 (migration precedent)
- §10 (Must)

## Description

This feature ensures no existing KB is stranded on the old format when the new
frontmatter schema and INDEX routing table land. Existing KBs — including **AID's
own** and **adopters'** — must be **migratable** to the new frontmatter
(`objective`/`summary`/`tags`/`see_also`/`owner`/`audience`/`sources`) and the new
INDEX format. The generator and skills must handle the transition, either
upgrade-in-place or via a migration step, **following AID's existing migration
precedent** (`migrate-work-hierarchy`, the content-isolation migration).

Per NFR-7, the migration must not break existing pipelines: an **un-migrated
old-format KB must keep functioning (degrade gracefully)** until it is upgraded,
and the migration must be **safe / reversible** per AID precedent. This is a
**Must** because every downstream AID phase loads the KB; a hard format break would
strand every existing project.

## User Stories

- As an **AID adopter** with an existing KB, I want my KB migrated to the new
  schema/INDEX format so that I get the overhaul without re-running discovery from
  scratch.
- As an **AID adopter** mid-upgrade, I want my un-migrated old-format KB to keep
  working so that nothing breaks before I migrate.
- As an **AID maintainer**, I want migration to follow existing precedent and be
  safe/reversible so that AID's own KB and adopters' KBs migrate predictably.

## Priority

Must

## Acceptance Criteria

- [ ] Given an old-format KB (AID's own and a fixture old-format KB), when migration
  runs, then it is upgraded to the new frontmatter schema and INDEX format. *(FR-30,
  AC9)*
- [ ] Given an un-migrated old-format KB, when the pipeline loads it, then it
  degrades gracefully and keeps functioning until upgraded. *(NFR-7, AC9)*
- [ ] Given the migration, when it runs, then it follows AID's existing migration
  precedent and is safe/reversible. *(FR-30, NFR-7)*

---

## Technical Specification

> Methodology/tooling feature — the **one-time, idempotent migration** that brings existing
> KBs (AID's own + adopters') from the old `intent:`-only frontmatter onto the new schema
> (f001) and INDEX format (f002), then makes the `lint-frontmatter.sh` **effectively hard FOR
> AID** by migrating AID's whole corpus into compliance (the shipped soft-skip is **retained**
> for adopter degrade-grace, NFR-7).
> "Components" here are a new shipped migration script under `canonical/aid/scripts/migrate/`,
> the existing `lint-frontmatter.sh` (a one-line scope-predicate widening; the soft-skip is
> retained), the existing `build-kb-index.sh`
> (re-run, not edited), AID's own ~16 in-scope KB docs (the dogfood migration; see *Scope* for
> the 15 `hand-authored` + the `host-tool-capabilities.md` edge case), and the CI wiring. Every
> claim is grounded against the files cited inline; genuine unknowns are flagged **[SPIKE]**,
> not guessed.
>
> **Boundaries (NOT redefined here — f011 migrates content INTO these, it does not author
> them).** The frontmatter **field schema** (`objective`/`summary`/`sources`/`tags`/`see_also`/
> `owner`/`audience`/`approved_at_commit`) + the **soft-skip lint** are **f001**'s. The INDEX
> **table format** + the `intent:` coexistence fallbacks (Objective<-collapsed intent,
> Summary<-first sentence) + the table-form `build-kb-index.sh` are **f002**'s. The
> `concern-model.md`, the expectations-as-open-questions transform, and the `intent:`->
> `objective`/`summary` supersession *decision* are **f003**'s. The concept-**spine structure**
> (`domain-glossary.md` upgrade) is **f004**'s. The **calibration grade** + review panel are
> **f005**'s. f011 is the **migration + making AID's lint effectively hard (by corpus
> migration; the shipped soft-skip is retained, NFR-7)**, nothing more.

### Overview

The new schema and INDEX format land via f001-f004 as **additive, backward-compatible**
changes: f001 ships the soft-skip lint, f002 ships the table-form generator with `intent:`
coexistence fallbacks, f003/f004 ship the concern model + spine structure. At that point
**0 of AID's 15** hand-authored primary/extension KB docs carry the new fields (verified on
disk, 2026-06-22: every `.aid/knowledge/*.md` hand-authored primary doc has `intent:` and
none has `objective:`/`summary:`/`sources:`). The KB still works — the f002 fallbacks render
a valid table, the f001 lint soft-skips, f003/f004's `aid-summarize`/discover repoints keep
their `intent:` fallback — but no doc is on the new schema. **f011 closes that window.**

f011 delivers, in dependency order:

1. **A migration script** (`canonical/aid/scripts/migrate/migrate-kb-frontmatter.sh`) that,
   per hand-authored primary/extension doc: seeds `objective:`/`summary:` from the existing
   `intent:` (reusing f002's exact collapse + first-sentence rules), **proposes** candidate
   `sources:`, stamps `approved_at_commit:`, and (once the human confirms) **retires
   `intent:`** — following the `migrate-work-hierarchy.sh` safe/reversible pattern
   (idempotent, `--dry-run`, backup, in-tree rollback).
2. **Human-gated field confirmation** — `objective`/`summary`/`sources:` are **proposed,
   then human-confirmed/refined** before they are written final (AID's gated ethos, NFR-6/C4).
3. **The glossary->spine migration** — fold AID's own `domain-glossary.md` content into the
   f004 concept-spine shape (the existing terms become concept entries / lexicon-table rows;
   no term lost).
4. **The INDEX regen** — re-run `build-kb-index.sh` (the f002 table generator) over the now-
   migrated KB and commit the result.
5. **The lint hard-flip (for AID)** — make `lint-frontmatter.sh` effectively hard **for AID**
   by migrating AID's whole corpus into compliance (the shipped soft-skip is RETAINED for
   adopter degrade-grace, NFR-7), plus an optional AID-CI-local strict assertion — done **after**
   AID's own docs are migrated, in the **same delivery**, so CI never half-enforces. The only
   shipped-lint edit is the orthogonal M1 scope-predicate widening (`hand-authored`->`!= generated`).

The whole change is **safe/reversible** (NFR-7): the migration backs up every file it
touches and can be rolled back; an un-migrated old-format KB keeps working until upgraded
(the f001/f002 coexistence window covers it). No new runtime (NFR-8/C1); the script is
ASCII-only shipped bash (C2); the only generator re-runs are deterministic (C3/render-drift).

### The Migration Script

**File:** `canonical/aid/scripts/migrate/migrate-kb-frontmatter.sh` (rendered to the 5 host
trees + the repo `.claude/` working copy, exactly like its sibling
`migrate-work-hierarchy.sh`). It is a **shipped migration script** that vendors into the
install bundles — the same class as `migrate-work-hierarchy.sh`, which is already in the
`test-ascii-only.sh` `SHIPPED_SCRIPTS` allow-list (verified, lines 41-42). So f011 adds
`migrate-kb-frontmatter.sh` to that allow-list and keeps it ASCII-only bash (PS-5.1 N/A —
bash). No LLM, no new dependency: pure coreutils (`awk`, `grep`, `sed`, `git`) — the
toolset `migrate-work-hierarchy.sh` and `build-kb-index.sh` already use.

**Invocation** (mirrors `migrate-work-hierarchy.sh`'s flag shape — positional KB root +
`--dry-run`, plus the human-gate flags this migration needs):

```bash
# 1. PROPOSE pass (default): write a per-doc proposal worksheet, change nothing.
bash .claude/aid/scripts/migrate/migrate-kb-frontmatter.sh .aid/knowledge --propose

# 2. APPLY pass (after the human edits/confirms the worksheet): write the confirmed fields.
bash .claude/aid/scripts/migrate/migrate-kb-frontmatter.sh .aid/knowledge --apply

# Inspect without writing (mirrors migrate-work-hierarchy --dry-run):
bash .claude/aid/scripts/migrate/migrate-kb-frontmatter.sh .aid/knowledge --apply --dry-run

# Undo the last APPLY from the backup it wrote:
bash .claude/aid/scripts/migrate/migrate-kb-frontmatter.sh .aid/knowledge --rollback
```

#### Scope (which docs the migration touches)

It runs **ONLY** on the path passed as `$1` (the `migrate-work-hierarchy.sh` SD-6 scope
discipline — never scans `$HOME` or other works; this is the [[aid-scan-tests-must-pin-home]]
hazard the precedent already guards). Within that KB root it selects the **same doc set the
f001 lint targets**: docs with `source: hand-authored` AND `kb-category:` in
`{primary, extension}`. It **skips**:

- `meta` docs (`README.md`, `STATE.md`, `release-tracking.md`) — outside the lint's scope.
- `source: generated` docs (`INDEX.md`, `project-structure.md`) — their frontmatter is
  generator-written, not hand-authored; `objective:`/`summary:` for these come from the
  generator (f001 Field Flow / f002), not the migration.

**Edge case flagged (verified on disk):** `host-tool-capabilities.md` carries
`source: promoted from work-local research (...)`, **not** the literal `source: hand-authored`.
Both the f001 lint and this migration key on `source: hand-authored`, so this doc would be
**skipped by both** — it would never be migrated AND never be lint-enforced, silently
escaping the hard gate. f011 MUST resolve this so the corpus is total: the migration treats
any `source:` value that is **not** `generated` (i.e. hand-authored OR a `promoted from ...`
provenance string) as in-scope for a `primary`/`extension` doc, and the f001 lint scope is
widened to match (lint applies to every `primary`/`extension` doc whose `source:` is not
`generated`). This is the one substantive change to the shipped lint script — the soft-skip
clause is RETAINED (see *The Lint Hard-Flip*). Net corpus for AID's dogfood = **16** docs (the 15 `hand-authored` +
`host-tool-capabilities.md`). **[SPIKE-M1]** — confirm with f001's owner that widening the
lint's `source:` predicate from `== hand-authored` to `!= generated` is acceptable, or
alternatively normalize `host-tool-capabilities.md`'s `source:` to `hand-authored` (it is no
longer "work-local" once promoted to the KB). Either resolution makes the corpus total; the
spec assumes the predicate-widening so a future promoted doc is auto-covered.

#### Per-doc transform (what it does to each in-scope doc)

For each in-scope doc, the migration performs these steps. **PROPOSE** writes them to a
worksheet (changes nothing on disk); **APPLY** writes the human-confirmed values into the
doc's frontmatter.

| # | Field | How the migration derives it | Human gate |
|---|-------|------------------------------|-----------|
| 1 | `objective:` | **Seed from `intent:`** using f002's *exact* Objective fallback: read the `intent:` literal block (via the `extract_literal` reader — the only part on-disk today, build-kb-index.sh lines 89-114) and apply f002's collapse-to-one-line transform (join on spaces, squeeze whitespace). The **collapse rule itself is f002's not-yet-built addition** (defined in feature-002 SPEC, Coexistence fallback), NOT a rule present in the current generator — f011 reuses the f002 transform so the migrated `objective:` reproduces the routing prose the f002 coexistence render produces. | Proposed; human refines to a tight noun-phrase (an `intent:` paragraph collapsed is long; the human trims it). |
| 2 | `summary:` | **Seed from the first sentence of the collapsed `intent:`** using f002's *exact* bounded deterministic sentence-boundary predicate (`[.!?](?=[ \t]+[A-Z]\|$)`, 200-char cap, ASCII ellipsis) — also an **f002 not-yet-built addition** defined in feature-002 SPEC (Coexistence fallback), NOT in the current build-kb-index.sh. Reusing f002's predicate verbatim keeps the migration and the coexistence-render byte-consistent. | Proposed; human refines to a clean one-sentence scope. |
| 3 | `sources:` | **Propose candidates** — the migration CANNOT infer what a doc summarizes, so it proposes a starter list it can mechanically derive and the human MUST confirm (see *Human-Gated Field Confirmation* and **[SPIKE-M2]**). Candidates: (a) any repo path mentioned in the doc's `intent:`/`contracts:` (grep `[\w./-]+\.(sh\|py\|md\|js\|mjs\|ts\|yml\|...)` + bare dir refs), (b) any registered external URLs the doc cites (the external-source registry path — note that for AID's own corpus `external-sources.md` registers NO URLs, so it does not exercise this candidate), (c) a `sources: []` proposal for a genuine pure-synthesis doc (the form `external-sources.md` actually takes — it states all knowledge was derived from repository content only). | Proposed candidates ALWAYS confirmed — `sources:` is never auto-finalized (the migration cannot know the true source set; it only seeds a starting point). |
| 4 | `approved_at_commit:` | **Stamp at migration-approval time** — `git rev-parse --short HEAD` captured during the APPLY pass (the commit at which the migrated doc is approved). f001 schema: 7-40 char lowercase hex; absence is valid pre-migration, presence is the freshness baseline f007 consumes. | Written by APPLY (generator-written field, never hand-authored — f001); no separate gate beyond approving the APPLY. |
| 5 | `intent:` retirement | **Finalize the supersession (f003 decision).** Once `objective:`/`summary:` are populated and confirmed, the legacy `intent:` literal block is **removed** from the doc's frontmatter (the `contracts:`/`changelog:` legacy fields are retained — they are not superseded). A `changelog:` row is appended recording the migration. | Gated: retirement happens only in APPLY, only after the objective/summary are confirmed-present (the migration refuses to retire `intent:` if objective/summary are still empty — degrade-safe). |
| 6 | optional fields | `tags:`/`see_also:`/`owner:`/`audience:` are **NOT auto-populated** (the migration cannot infer them well). They are left absent (valid — optional in f001) for the human to add later via normal authoring, OR pre-seeded blank in the worksheet for optional human fill. | Optional; absence is valid. |

The transform writes the new fields in the f001 canonical field order
(`objective`/`summary`/`sources`/optional/`approved_at_commit`) above the retained legacy
`contracts:`/`changelog:` block, matching the f001 "Updated canonical YAML block."

#### Idempotency (the migrate-work-hierarchy contract)

`migrate-work-hierarchy.sh` is idempotent: "if any per-task STATE.md already exists, the
entire work is skipped (no-op)" (its lines 18, 577-581). f011's analogue: **a doc that
already carries `objective:` AND `summary:` AND a `sources:` KEY (i.e. already migrated) is
skipped** (no re-seed, no re-stamp, no double `changelog:` row). The skip predicate MUST key on
the **presence of the `sources:` key — including the empty-list form `sources: []`** — NOT on a
non-empty value: f001 makes `sources: []` a valid terminal state for a pure-synthesis doc (e.g.
`external-sources.md`), so a presence-of-value test would mis-classify a correctly-migrated
`sources: []` doc as un-migrated and re-run it every pass (re-stamp `approved_at_commit:`,
double `changelog:` row). Keying on key-presence keeps the migration idempotent over
pure-synthesis docs. A re-run over a fully
migrated KB is a clean no-op; a re-run over a partially migrated KB (some docs migrated, some
not — the mixed window) migrates only the un-migrated remainder. This makes APPLY safe to
re-run and safe to interrupt — exactly the precedent's guarantee.

#### Dry-run, backup, rollback (the safe/reversible contract — NFR-7)

- **`--dry-run`** (on either `--propose` or `--apply`): prints every action it would take and
  writes nothing — the `migrate-work-hierarchy.sh` `DRY_RUN` flag verbatim (its lines 532,
  641-666 "DRY-RUN: would ...").
- **Backup (before APPLY writes).** Before modifying any doc, APPLY copies it to a sibling
  backup tree `.aid/.temp/kb-migration-backup-<UTC-timestamp>/<doc>.md` (the project's existing
  transient `.aid/.temp/` tree, which `kb-hygiene` already expects to be gitignored — verified
  the kb-hygiene job checks `.aid/.temp` is not committed). The backup is the rollback source.
- **`--rollback`.** Restores every doc from the most recent backup tree, then removes that
  backup tree. This is the safe/reversible exit NFR-7 + FR-30 require. (`migrate-work-hierarchy.sh`
  achieves reversibility by *retaining* the legacy flat `tasks/` files; f011's frontmatter edit
  is in-place, so it needs an explicit backup — the same reversibility guarantee, realized for
  an in-place edit rather than an additive layout change.)
- **Verification pass (before declaring success).** Like `migrate-work-hierarchy.sh`'s Pass 4
  non-empty checks (its lines 744-764), APPLY re-reads each migrated doc and asserts the
  required fields are present + well-formed by **shelling out to `lint-frontmatter.sh` on the
  migrated doc** (the same oracle CI uses), failing loud (non-zero exit) and pointing at the
  backup if any doc did not come out lint-clean. The migration and the lint thus share one
  definition of "migrated correctly."

### Human-Gated Field Confirmation

The migration **proposes, the human confirms** — it never silently auto-finalizes
`objective`/`summary`/`sources:` (NFR-6 trust/visibility, C4 human-gated, AID's gated
state-machine ethos; the [[ask-user-over-auto-proof]] precedent — annotate + let the human
confirm, don't auto-hide what a heuristic cannot prove).

**The two-pass propose->confirm flow:**

1. **PROPOSE pass writes a worksheet, not the docs.** `--propose` emits
   `.aid/.temp/kb-migration-proposal.md` — one section per in-scope doc, each with the
   mechanically-seeded `objective:` (collapsed intent), `summary:` (first sentence), and the
   **proposed `sources:` candidate list** (with each candidate annotated by how it was
   derived: "from intent path ref", "external URL", "pure-synthesis -> sources: []"). It
   changes nothing on disk (it is itself a `--dry-run`-grade read).
2. **Human reviews + refines the worksheet.** The orchestrating skill
   (`aid-discover`/`aid-update-kb` driving the migration, or the maintainer running it
   directly) pauses for the human to: tighten each `objective:` noun-phrase, refine each
   `summary:`, and — critically — **confirm/correct the `sources:`** for each doc (add the
   real sources the heuristic missed, drop false positives). This is the gate: `sources:` is
   the keystone primitive (f001) and the migration cannot know the true source set, so a human
   MUST sign off on it. The worksheet is editable markdown; the human edits it in place.
3. **APPLY reads the confirmed worksheet and writes the docs.** `--apply` reads the
   (human-edited) `kb-migration-proposal.md`, writes the confirmed fields into each doc,
   retires `intent:`, stamps `approved_at_commit:`, and runs the verification pass. If the
   worksheet is absent, APPLY refuses (it will not finalize un-confirmed fields) — directing
   the user to run `--propose` first. This makes the human confirmation a **hard
   precondition** of finalization, not an optional review.

For **AID's own dogfood migration** the worksheet is reviewed by the maintainer at the gate;
for an **adopter**, the same worksheet is the artifact their KB owner confirms. The proposal
worksheet is transient (`.aid/.temp/`, gitignored) — it is scaffolding for the gate, not a
committed artifact (consistent with the [[prose-over-scripts]] / keep-run-state-out-of-data
ethos).

### The Lint Hard-Flip (for AID — via corpus migration, NOT by deleting the soft-skip)

f001 ships `lint-frontmatter.sh` in **soft-skip** mode (its day-one behavior, f001 SPEC
"Validation & Migration": *"skips any doc that does not yet carry ANY of the new fields
(pre-migration)"* and *"becomes a hard gate ... only after f011 migrates AID's own docs"*).
**f011 makes the lint hard FOR AID by migrating AID's entire corpus into compliance — the
shipped soft-skip is RETAINED, not deleted** ([SPIKE-M5] RESOLVED, NFR-7). A migrated doc
naturally falls through the soft-skip into enforcement; an un-migrated adopter doc still
degrades gracefully. AID's own hardness comes from "all AID docs migrated" plus an optional
AID-CI-local strict assertion — both detailed below.

**What "flip" means here — and what it does NOT mean.** f011's "flip" is realized **by
migrating AID's entire corpus into compliance**, NOT by deleting the soft-skip clause from the
shipped script. The shipped `lint-frontmatter.sh` **RETAINS** the day-one soft-skip — the
predicate that skips a doc carrying NONE of the new fields ([SPIKE-M5] RESOLVED: retain;
NFR-7). The retained soft-skip is what keeps an adopter who upgrades-but-has-not-migrated
degrade-graceful, and it is **naturally self-tightening per doc**: a migrated doc carries the
new fields -> the skip does not fire -> it is enforced; an un-migrated doc carries none -> it
is skipped. So once f011 migrates all 16 AID docs, the soft-skip **never fires for AID** (no
AID doc is pre-migration), and the lint enforces required-field presence/shape on every AID
in-scope doc — without any deletion. Concretely, the shipped predicate is **unchanged** in its
soft-skip:

- **Shipped lint (unchanged soft-skip, before AND after f011):** `for each in-scope doc: if
  doc carries none of {objective,summary,sources,tags,see_also,owner,audience} -> SKIP
  (pre-migration); else check required presence + shape.` After AID's dogfood migration the
  SKIP branch is never taken for AID's own docs (they all carry the fields), so AID is fully
  enforced de facto; an adopter's un-migrated docs still skip (NFR-7 degrade-graceful).
- **The one shipped-lint edit f011 makes — scope predicate widening only** ([SPIKE-M1]
  above, orthogonal to the soft-skip): the in-scope predicate becomes "`kb-category` in
  {primary, extension} AND `source:` != generated" (was `source: == hand-authored`), so
  `host-tool-capabilities.md` is covered. This is the **single** change to the shipped script;
  the soft-skip clause, the required-field + shape checks, and the `[FM-MISSING]`/
  `[FM-INVALID]` rubric tags (f001) are all unchanged.
- **AID's own strictness — corpus migration + an AID-CI strict assertion.** AID hard-gates
  itself two ways: (1) f011 migrates AID's *entire* corpus so the shipped soft-skip never fires
  for AID, and (2) an **optional AID-repo-specific strict assertion in AID's own CI** — a check
  that every primary/extension KB doc in AID's repo carries the required fields, guarding
  against an un-migrated doc sneaking into AID's repo (a doc the shipped soft-skip would
  otherwise silently let pass). The strict assertion is AID-CI-local, NOT a change to the
  shipped lint; the `meta` + `source: generated` scope skips REMAIN under both (they are
  permanently out of scope, not "pre-migration").

**When (order of operations — the load-bearing sequencing):** within f011's delivery, AID's
own docs MUST be migrated and the regenerated INDEX committed **before** the strict AID-CI
assertion is in force, **in the same commit/PR**, so AID's CI never observes a strict check
over un-migrated AID docs. The safe order ([SPIKE-M3] resolved here):

1. Run `migrate-kb-frontmatter.sh --propose`, confirm the worksheet, run `--apply` over
   `.aid/knowledge/` (migrates all 16 dogfood docs).
2. Run the glossary->spine migration (below) so `domain-glossary.md` is on the spine shape.
3. Re-run `build-kb-index.sh` (f002 table generator) -> regenerated `.aid/knowledge/INDEX.md`
   (now built from real `objective:`/`summary:`/`tags:`, not the `intent:` fallback).
4. Edit `lint-frontmatter.sh`: widen the in-scope predicate to `source: != generated`
   (the single shipped-lint change). **The soft-skip clause is RETAINED** (NFR-7); no deletion.
   Land/enable the optional AID-CI-local strict assertion (every AID primary/extension doc
   carries the required fields) — AID-repo-specific, not a change to the shipped lint.
5. Re-run `python .claude/skills/generate-profile/scripts/run_generator.py` (the lint + the
   migration script are canonical; their rendered copies must refresh — render-drift).
6. Commit all of (1)-(5) **together**. AID's CI then runs the strict assertion over a
   fully-migrated AID KB -> green; never over a mixed/un-migrated state.

**The CI implication (kb-hygiene goes effectively-hard for AID).** f001 added the
`lint-frontmatter.sh` step to the `kb-hygiene` job (test.yml, the job at lines 98-124) in
soft-skip mode (green over the 0-of-15 un-migrated docs). The shipped lint **keeps** that
soft-skip after f011 (NFR-7). For AID's own repo the gate nonetheless becomes effectively
hard, two ways: (1) once AID's docs are all migrated the soft-skip never fires for them, so the
existing step enforces required-field presence/shape on every AID in-scope doc; and (2) the
optional **AID-CI-local strict assertion** (step 4 above) makes the strictness explicit and
catches any un-migrated AID doc the soft-skip would otherwise pass. The shipped step's
*behavior is unchanged* (it still soft-skips for adopters); only the data it sees in AID's repo
(a fully-migrated corpus) plus AID's own strict assertion make it effectively hard for AID. For
this to be green, AID's own docs MUST be migrated in the same change (step 1 above) — which is
exactly f011's dogfood deliverable. The "INDEX.md is fresh" step (lines 116-124) stays green
because f011 commits the regenerated table-form INDEX (step 3).

### Glossary->Spine Migration

f004 upgrades the `domain-glossary.md` *template* to the concept-spine structure (concept
entries with definition-as-used-here / relates-to / per-concept `sources:`, plus the retained
lexicon tables). f011 **migrates AID's own existing `.aid/knowledge/domain-glossary.md`
content into that shape** (f004 defines the structure; f011 moves the existing glossary
content into it — the explicit f004 boundary: *"f011 migrates AID's own glossary"*).

This is a **content migration, judgment-bearing, human-gated** — not a mechanical field
seed. The existing AID glossary is a set of term/definition/source tables (Phase names, role
names, pipeline concepts, ...). The migration:

1. **Promotes load-bearing native concepts to concept entries.** The terms that are
   *load-bearing native concepts* (e.g. Phase Gate, Two-Tier Review, Pool Dispatch,
   canonical->render, Thin-Router) become structured concept entries with
   definition-as-used-here + relates-to + per-concept `sources:`.
2. **Retains the rest as lexicon tables** (f004's "term/definition tables (retained)" — the
   vocabulary-but-not-load-bearing terms stay as scoped tables). **No term is lost** (f004's
   additive-upgrade guarantee).
3. **Adds the doc-level frontmatter** via the same `migrate-kb-frontmatter.sh` pass as every
   other doc (objective/summary from intent, `sources:` = the union of the concept-level
   sources, confirmed by the human).

Because this is judgment-bearing (which terms are "load-bearing native concepts" is the same
calibration f005 grades), f011 does it as an **`aid-update-kb`/`aid-discover`-driven step
through the review gate**, not a pure script: the script seeds the frontmatter; the
spine-shaping of the body is a human-confirmed authoring step. **[SPIKE-M4]** — sequencing:
this consumes f004's upgraded template + f003's C4 concept-model designation; confirm with
PLAN.md that f003+f004 land before f011's glossary step (the spine *structure* must exist
before AID's glossary content is migrated into it).

### INDEX Regeneration (f002 format)

After the per-doc migration + glossary->spine, f011 re-runs `build-kb-index.sh` (the f002
**table** generator) over the migrated `.aid/knowledge/` and commits the regenerated
`INDEX.md`. Now that every in-scope doc carries real `objective:`/`summary:`/`tags:`/`see_also:`/
`audience:`, the table is built from the **real fields** rather than the f002 `intent:`
coexistence fallback — the fallback rows disappear as each doc is migrated. f011 does **not**
edit the generator (f002 owns it); f011 only **runs** it and commits the result. The
"INDEX.md is fresh" CI step (regen + timestamp-filtered diff, format-agnostic) stays green
because the committed INDEX is the regenerated one (the same contract f002 relies on).

### AID's Own Dogfood Migration + the Adopter Path

**Dogfood (AID's own KB, the 16 docs).** f011's delivery migrates AID's own
`.aid/knowledge/` as the **first executor** of the migration — proving the script + the
glossary->spine + the INDEX regen + the effectively-hard lint (corpus migration + AID-CI strict
assertion; soft-skip retained) on the real corpus before any adopter runs
it. This is the [[aid-content-isolation-cornerstone]] dogfood discipline: AID ships nothing
it has not first run on itself. The dogfood migration is the AC9 evidence ("AID's own KB ...
migrates to the new schema"). The 16-doc list is enumerated above (15 `hand-authored` +
`host-tool-capabilities.md`); `meta` + `generated` docs are intentionally untouched.

**Adopter-facing path.** An adopter on an old-format KB runs the **same shipped script** that
f011 ran on AID's own KB (it vendors into every install bundle). The path is:
`migrate-kb-frontmatter.sh --propose` -> confirm the worksheet -> `--apply` -> re-run their
`build-kb-index.sh`. The adopter's lint experience differs from AID's by design: AID's lint
becomes effectively hard in f011 **because AID migrated its own docs** (the retained soft-skip
never fires for AID) plus AID's CI strict assertion; an **adopter's** lint runs the **same
shipped logic** — its retained soft-skip enforces required fields on docs that carry the new
schema and skips un-migrated docs, so an adopter who upgrades-but-has-not-migrated degrades
gracefully (NFR-7) and each doc becomes enforced as it is migrated. **[SPIKE-M5] — RESOLVED
(retain soft in shipped + AID-CI strict):** the shipped `lint-frontmatter.sh` **keeps** the
soft-skip, so an adopter who upgrades AID but has NOT yet run the migration keeps degrading
gracefully — the soft-skip becomes per-doc-strict naturally as each doc migrates (a migrated
doc has the fields -> enforced; an un-migrated doc has none -> skipped). AID's own strictness
is achieved by (1) f011 migrating AID's *entire* corpus into compliance (so the soft-skip
never fires for AID) **plus** (2) an optional AID-CI-local strict assertion (every AID
primary/extension doc carries the required fields), NOT by deleting the soft-skip. The
alternative considered — (b) gating a hard lint on the `aid update` per-repo migration stamp
([[cli-install-scope-redesign]]) — is NOT adopted; the retain-soft + per-doc-natural-tightening
approach is simpler, precedent-aligned ([[ask-user-over-auto-proof]] / degrade-graceful), and
honors NFR-7 without a stamp dependency. This is a RESOLVED architect decision, not an open
PLAN question.

### Backward-Compatibility / Safe-Reversible (NFR-7) + Precedent Reuse

**Degrade-gracefully (un-migrated old-format KB keeps working).** This is guaranteed by the
f001/f002/f003 coexistence machinery, NOT by f011 — f011's job is to make the migration
*safe*, while the *window* it migrates across is already covered:

- The f002 `build-kb-index.sh` falls back `objective`<-`intent` and Summary<-first-sentence,
  so an un-migrated KB still renders a valid INDEX.
- The f001 lint soft-skips pre-migration docs, and f011 **retains** that soft-skip in the
  shipped lint ([SPIKE-M5] RESOLVED) — so the *adopter's* shipped lint stays degrade-graceful
  until they run the migration, tightening per-doc as each doc migrates.
- f003's `aid-summarize` repoint keeps its `intent:` fallback; f007 treats absent
  `approved_at_commit:` as "baseline unknown", never an error.
- A **mixed** KB (mid-migration: some docs migrated, some not) renders each doc by its own
  fields (f002's per-row fallback) — **no doc breaks mid-flight**, which is exactly why the
  migration can be idempotent + interruptible.

**Safe/reversible (the migration itself) — precedent reuse, with ONE net-new primitive.** f011
reuses `migrate-work-hierarchy.sh`'s proven safety primitives where the precedent actually has
them (idempotency, `--dry-run`, scope discipline, the verification pass, exit-code discipline).
**The explicit backup + `--rollback` is the exception: it is f011-NOVEL, not precedent-reused.**
`migrate-work-hierarchy.sh` has NO backup/rollback/restore mechanism (grep confirms none); it
achieves reversibility purely *additively* — it retains the legacy flat `tasks/` files and
never edits in place. f011's frontmatter edit IS in-place, so it cannot lean on retention and
must add an explicit backup tree + `--rollback` restore. This is the migration's largest
net-new safety surface (it carries the most novel risk), so the canonical suite asserts
`--rollback` restores byte-identity (below). The table below marks which primitives are reused
verbatim vs. realized newly for an in-place edit:

| Precedent primitive (migrate-work-hierarchy.sh) | f011 reuse |
|---|---|
| Idempotent no-op on already-migrated (lines 18, 577-581) | A doc carrying `objective:` + `summary:` + a `sources:` key (presence, incl. `sources: []`) is skipped; re-run is clean — keying on key-presence keeps `sources: []` pure-synthesis docs idempotent. |
| `--dry-run` prints-only (lines 532, 641-666) | `--dry-run` on propose/apply. |
| Scope discipline SD-6 — runs only on `$1`, never scans `$HOME` (lines 26-27, 556-568) | Same; guards the [[aid-scan-tests-must-pin-home]] hazard. |
| Verification pass before success (Pass 4, lines 744-764) | APPLY shells `lint-frontmatter.sh` per doc; fails loud + points at backup. |
| Reversibility (retains legacy `tasks/` files) | f011 is in-place, so it adds an explicit `.aid/.temp/` backup + `--rollback` (same guarantee, realized for an in-place edit). |
| Exit-code discipline (lines 33-40) | Distinct exit codes: bad KB root / no in-scope docs / un-confirmed worksheet on `--apply` / verification failure. |

The canonical test suite `tests/canonical/test-migrate-kb-frontmatter.sh` (auto-discovered by
`tests/run-all.sh`'s glob, run in the `canonical-tests` job) mirrors
`test-aid-migrate.sh`'s pattern and asserts: idempotent re-run is a no-op; `--dry-run` writes
nothing; a fixture old-format doc migrates to lint-clean; `--rollback` restores byte-identity;
`intent:` is retired only after objective/summary are present; the verification pass fails on a
deliberately-broken migrated doc. The suite MUST pin `HOME` + use a throwaway fixture KB root
(NOT `.aid/knowledge/`), per the [[aid-scan-tests-must-pin-home]] hazard.

### Affected Components

| Component | Path | Change |
|-----------|------|--------|
| **NEW migration script** | `canonical/aid/scripts/migrate/migrate-kb-frontmatter.sh` | The propose/apply/dry-run/rollback migration: seed objective/summary from intent (f002 rules), propose sources, stamp approved_at_commit, retire intent, backup+verify. ASCII bash; reuses migrate-work-hierarchy's scope/idempotency/dry-run/verify primitives. |
| Lint (scope widen only) | `canonical/aid/scripts/kb/lint-frontmatter.sh` (f001-created) | Widen the in-scope predicate from `source: == hand-authored` to `source: != generated` (the single shipped-lint edit). **RETAIN** the day-one pre-migration soft-skip clause (NFR-7, [SPIKE-M5] RESOLVED) — AID's hardness comes from migrating its whole corpus, not from deleting the soft-skip. No change to the soft-skip, the required-field/shape checks, or the `[FM-MISSING]`/`[FM-INVALID]` tags (f001). |
| AID-CI strict assertion (optional) | `.github/workflows/test.yml` (`kb-hygiene` job, AID-repo-local) | Optional AID-repo-specific strict check that every AID primary/extension KB doc carries the required fields — guards against an un-migrated doc sneaking into AID's repo (which the retained shipped soft-skip would pass). NOT a change to the shipped lint. |
| ASCII guard | `tests/canonical/test-ascii-only.sh` | Add `canonical/aid/scripts/migrate/migrate-kb-frontmatter.sh` to `SHIPPED_SCRIPTS` (alongside the existing `migrate-work-hierarchy.sh`). |
| AID's own KB (dogfood) | `.aid/knowledge/*.md` (16 in-scope docs) | Migrated: objective/summary/sources/approved_at_commit added, intent retired, changelog row appended; `domain-glossary.md` additionally folded into the f004 spine shape. |
| INDEX (regen) | `.aid/knowledge/INDEX.md` | Regenerated by re-running the f002 `build-kb-index.sh` over the migrated KB; committed (keeps INDEX-fresh green). f011 runs, does not edit, the generator. |
| CI — kb-hygiene | `.github/workflows/test.yml` (job `kb-hygiene`, lines 98-124) | The existing f001-added `lint-frontmatter.sh` step is **unchanged in behavior** (still soft-skips); for AID it becomes effectively hard because all AID docs are migrated (soft-skip never fires) plus the optional AID-CI strict assertion. Green because AID's own docs are migrated in the same change. |
| CI — canonical suite | `tests/canonical/test-migrate-kb-frontmatter.sh` (NEW) + fixtures | Mechanical assertions: idempotency, dry-run, migrate-to-lint-clean, rollback byte-identity, intent-retire ordering, verify-pass failure. HOME-pinned, throwaway fixture KB. |
| render-drift | `test.yml` job `render-drift` | No edit; the new migration script + the edited lint are canonical -> re-run `run_generator.py`, commit regenerated `profiles/` (render-drift-full-generator precedent). |

### Constraints

- **C2 / Q2 — ASCII-only.** `migrate-kb-frontmatter.sh` vendors into the install bundles ->
  ASCII-only bash (PS-5.1 N/A). Added to `test-ascii-only.sh`'s `SHIPPED_SCRIPTS`. The
  `changelog:` rows it writes into KB docs are markdown (not gated) but SHOULD stay ASCII for
  consistency. **[SPIKE-M6]** — confirm the script's seeded literals (the f002 sentence
  predicate `[.!?]`, `[A-Z]`, the `...` ellipsis) are ASCII (they are — f002 already
  guarantees this) so adding it to the guard does not red CI.
- **C3 / NFR-4 — render-drift green.** The migration script + the lint edit are canonical;
  edit canonical only, re-run `python .claude/skills/generate-profile/scripts/run_generator.py`,
  commit the regenerated `profiles/`. Never hand-edit a rendered copy. **[SPIKE-M7]** — verify
  the renderer auto-discovers a net-new `scripts/migrate/*.sh` (it enumerates the tree, and the
  sibling `migrate-work-hierarchy.sh` already renders, so expected yes); if an emission manifest
  pins the `scripts/migrate/` list, update canonical + regen, never hand-place.
- **NFR-8 / C1 — no new runtime.** Pure coreutils (`awk`/`grep`/`sed`/`git`) — the toolset
  `migrate-work-hierarchy.sh`/`build-kb-index.sh` already use. No embedding model, binary, MCP,
  or `python3`/`pwsh` escalation. The migration is a one-time/idempotent script, not a runtime
  path.
- **NFR-6 / C4 — human-gated.** Detection/seeding is mechanical; **finalization is human-gated**
  (the propose->confirm worksheet; APPLY refuses without a confirmed worksheet). `sources:` is
  never auto-finalized. KB content changes require human approval (the dogfood migration is
  approved by the maintainer at the gate; an adopter's by their KB owner).
- **C6 — content-isolation.** The migration script is namespaced under `aid/scripts/migrate/`
  (the existing isolated tree); its transient artifacts (proposal worksheet, backup tree) live
  under `.aid/.temp/` (gitignored), not in the committed KB.
- **NFR-3 / C5 — determinism.** The mechanical seeding (collapse intent, first-sentence
  predicate, idempotency check) is deterministic and CI-asserted by the canonical suite. The
  judgment surface (the human refining objective/summary/sources, the glossary spine-shaping)
  is the irreducible human gate, not a non-deterministic machine decision.

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-M1] — scope totality (the `host-tool-capabilities.md` edge).** That doc's
  `source:` is `promoted from work-local research (...)`, not `hand-authored`, so the f001
  lint + the migration both skip it. Spec resolves by widening the in-scope predicate to
  `source: != generated` (covers it) — confirm with f001's owner, or alternatively normalize
  the doc's `source:` to `hand-authored`. Either makes the corpus total (16, not 15). **This
  is the most important spike** — a missed doc silently escapes the hard gate.
- **[SPIKE-M2] — `sources:` bootstrap for the 16 existing docs.** The migration cannot infer
  what a doc summarizes; it proposes candidates (intent/contracts path refs, external URLs,
  `sources: []` for pure-synthesis) and the human MUST confirm. The genuine unknown is **how
  good the mechanical candidate proposal is** — for some docs (`architecture.md`,
  `module-map.md`) the path refs in `intent:`/`contracts:` give a strong start; for others (a
  conceptual doc with no path refs) the proposal may be near-empty and the human supplies
  `sources:` from scratch. The propose->confirm worksheet is designed for exactly this: it
  surfaces the candidates AND leaves the human to complete them; the quality of the AID-own
  bootstrap is the dogfood evidence for whether the candidate heuristic is worth shipping or
  whether `sources:` should be human-authored from a blank prompt. Calibrate against the
  dogfood run.
- **[SPIKE-M3] — RESOLVED: order of operations (lint scope-widen + AID strict-assertion vs
  dogfood commit).** Resolved in-spec (see *The Lint Hard-Flip* -> *When*): migrate docs ->
  glossary->spine -> regen INDEX -> widen lint scope (soft-skip retained) + enable the AID-CI
  strict assertion -> regen profiles -> commit ALL together, so AID's CI never observes a strict
  check over un-migrated AID docs. Not an open unknown; stated as the load-bearing sequencing
  the gate must hold f011 to.
- **[SPIKE-M4] — sequencing (f003/f004 before f011's glossary step).** The glossary->spine
  migration consumes f004's upgraded template + f003's C4 designation; confirm with PLAN.md
  that f003+f004 land before f011 (provide-before-consume). f011 also consumes f001 (schema +
  lint) and f002 (table generator + fallback rules) — so **f011 is necessarily late in the
  delivery order** (it depends on f001-f004). Confirm the full f001..f004 -> f011 ordering.
- **[SPIKE-M5] — RESOLVED: adopter backward-compat vs AID's own hard lint.** The tension was:
  AID wants a hard lint, but an *adopter* who upgrades-but-has-not-migrated must keep degrading
  gracefully (NFR-7). **Resolution (architect decision): RETAIN the soft-skip in the shipped
  `lint-frontmatter.sh` + add an optional AID-CI-local strict assertion.** The shipped lint
  keeps its soft-skip, so an un-migrated adopter doc still skips (NFR-7); the soft-skip becomes
  per-doc-strict naturally as each doc migrates (migrated doc has the fields -> enforced;
  un-migrated doc has none -> skipped). AID's own hardness = f011 migrating AID's *entire*
  corpus (so the soft-skip never fires for AID) **plus** an AID-repo-specific strict CI check
  (every AID primary/extension doc carries the required fields), guarding against an un-migrated
  doc sneaking into AID's repo. The soft-skip is **NOT deleted**; the only shipped-lint edit is
  the orthogonal M1 scope-predicate widening (`hand-authored`->`!= generated`). The alternative
  (gate a hard shipped lint on the `aid update` per-repo migration stamp,
  [[cli-install-scope-redesign]]) is NOT adopted — it adds a stamp dependency the
  retain-soft approach does not need. Not an open PLAN decision.
- **[SPIKE-M6] — ASCII of seeded literals.** Confirm the f002 sentence predicate literals the
  migration reuses are ASCII (expected yes — f002 guarantees it) before adding the script to
  the ASCII guard.
- **[SPIKE-M7] — net-new `scripts/migrate/*.sh` render.** Verify `run_generator.py`
  auto-discovers the new migration script (the sibling already renders, so expected yes); if an
  emission manifest pins the `scripts/migrate/` list, update canonical + regen, never
  hand-place (render-drift-full-generator precedent).
