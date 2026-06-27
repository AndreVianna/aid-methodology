# Frontmatter & `sources:` Primitive

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-2, FR-4, FR-10) + §1.7 render plumbing (GAP-B) | /aid-interview |

## Source

- REQUIREMENTS.md §5.A (FR-2), §5.B (FR-4), §5.C (FR-10)
- REQUIREMENTS.md §1.3 (the `sources:` primitive rationale), §1.7 (frontmatter feeding the INDEX)
- Cross-cutting NFR-4 (canonical→render, CI-guarded), C3, C7

## Description

This feature establishes the shared frontmatter vocabulary that the rest of the
KB overhaul depends on. It adds new frontmatter fields to every KB document so
the document can describe itself to both the routing layer and the freshness
layer: `objective:` (one-line purpose), `summary:` (one-sentence scope),
`tags:` (concrete project terms), `see_also:` (negative-routing pointers),
`owner:` (the role accountable for the doc), `audience:` (who the doc is for),
and `sources:` (the files, directories, and external docs the doc summarizes).

The `sources:` field is the keystone primitive — it is required by three threads
at once (the INDEX go-deeper pointer, per-doc source-keyed freshness, and the
calibration/coverage grading), which is why it is built once, here, as a
foundation. Beyond the field definitions, this feature delivers the render
plumbing (GAP-B): the canonical frontmatter-schema and the generator must parse,
validate, and carry these fields end-to-end so downstream features (INDEX
routing, freshness, calibration) can consume them without re-plumbing.

## User Stories

- As an **AI agent**, I want every KB doc to declare its objective, summary, and
  tags in structured frontmatter so that I can be routed to the right doc cheaply
  and deterministically.
- As a **doc owner / maintainer**, I want each doc to declare its `sources:` and
  `owner:` so that I know which doc my change made suspect and who is accountable
  for keeping it current.
- As an **AID maintainer**, I want the frontmatter schema and the canonical→render
  generator to validate the new fields so that the new primitive is CI-guarded and
  cannot drift.

## Priority

Must

## Acceptance Criteria

- [ ] Given the KB frontmatter schema, when a KB doc is authored, then it can
  declare `objective:`, `summary:`, `tags:`, `see_also:`, `owner:`, `audience:`,
  and `sources:` and the schema validates them. *(FR-2, FR-10, FR-4)*
- [ ] Given a KB doc with the new fields, when the canonical→render generator runs,
  then the fields are parsed, validated, and carried through with render-drift and
  KB-hygiene CI green (GAP-B render plumbing). *(NFR-4, C3, C7; supports AC12)*
- [ ] Given any KB doc, when it is checked, then it declares `sources:` — the
  files/dirs/external docs it summarizes. *(FR-4; foundation for AC5)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 deterministic
> substrate at the frontmatter layer (schema validation is mechanical, CI-able,
> no LLM). It is the foundation consumed by AC4 (f002), AC5 (f007), and the
> calibration coverage-vs-source check (f005).

---

## Technical Specification

> Methodology/tooling feature. This extends AID's KB **frontmatter schema** and the
> **canonical→render** plumbing — it is not application code. "Components" below are
> templates, the `build-kb-index.sh` parser/generator, the canonical-render generator,
> and CI gates. Every claim is grounded against the files cited inline. Genuine unknowns
> are called out as **[SPIKE]** rather than guessed.

### Overview

This feature delivers the shared frontmatter vocabulary the rest of work-001 consumes. It
(1) adds new frontmatter fields to the schema and every KB-doc template, (2) teaches
`build-kb-index.sh` to parse them and emit the new INDEX **routing table**, (3) carries
the change through the canonical→render generator to the five host trees with
`render-drift` green, and (4) adds a **deterministic field-validation lint** for the new
*required* fields, which are carved out of the P6 "frontmatter exempt from review"
exemption.

Confirmed design decisions this spec builds on (user-approved; not re-litigated):

1. `objective:` + `summary:` **supersede** `intent:` as the INDEX routing source.
   `intent:` is **retired via the f011 migration** (FR-30); a coexistence window applies
   (see Validation & Migration). `aid-summarize` moves its section-description source from
   `intent:` to `objective`/`summary` (tracked in f009/aid-summarize alignment; this
   feature only makes the fields *available* — it does not edit `aid-summarize`).
2. The new **required** fields (`objective`, `summary`, `sources`) are **carved out** of
   the P6 frontmatter exemption and get a deterministic presence/well-formedness lint.
   Legacy informational fields (`intent`, `contracts`, `changelog`, `kb-category`,
   `source`, `generator`) and the new **optional** fields stay exempt from *content*
   grading.
3. Field roster — **required (hand-authored):** `objective`, `summary`, `sources`;
   **optional:** `tags`, `see_also`, `owner`, `audience`; **generator-written:**
   `approved_at_commit:` (stamped on approval by `aid-discover`/`aid-update-kb`, never
   hand-authored).

### Frontmatter Schema

The schema doc is `canonical/aid/templates/kb-authoring/frontmatter-schema.md` (rendered
copy at `.claude/aid/templates/kb-authoring/frontmatter-schema.md`). New fields:

| Field | YAML type | Class | Default | Semantics | Well-formedness rules |
|-------|-----------|-------|---------|-----------|------------------------|
| `objective:` | scalar string (one line) | **required**, hand-authored | none (lint error if absent) | The doc's purpose as a noun-phrase — the INDEX "Objective" column (FR-1). Supersedes `intent:` for routing. | Non-empty after trim; single physical line (no `\|`/`>` block); SHOULD be a noun-phrase, not a sentence. Length is advisory, not lint-enforced. |
| `summary:` | scalar string (one line) | **required**, hand-authored | none (lint error if absent) | One-sentence scope — the INDEX "Summary" column (FR-1). | Non-empty after trim; single physical line. (Two distinct single-line scalars rather than reusing the `intent:` literal block keeps the generator's single-line extractor — `extract_field` — sufficient and avoids the multi-line `extract_literal` path for routing.) |
| `sources:` | list of strings | **required**, hand-authored | none (lint error if absent; empty list **allowed** with a sentinel — see rules) | The files/dirs/external docs/URLs the doc summarizes (FR-4). Keystone primitive: consumed by INDEX go-deeper (f002), per-doc freshness (f007), calibration coverage (f005). | A YAML list. Each entry is one of: a **repo-relative path** (`src/foo.ts`), a **glob** (`src/parsers/*.py`), or a **URL** (`https://…`). A doc with genuinely no sources (e.g. a pure synthesis/glossary) MUST declare `sources: []` explicitly — absence is a lint error, empty-list is valid (mirrors the existing `contracts: []` convention). Path/glob/URL *resolution* is NOT checked by this feature's lint (that is f007 freshness); the lint here checks *shape* only. |
| `tags:` | list of short strings | optional | `[]` | Concrete project keywords for the INDEX "Tags" column (FR-2). | If present, a YAML list of short strings (no embedded newlines). No controlled vocabulary — free project terms. |
| `see_also:` | list of strings | optional | `[]` | Negative-routing pointers — "use that doc instead" — the INDEX "See-instead" column (FR-2). | If present, a YAML list. Each entry SHOULD be a sibling **doc name** (`schemas.md`) so the INDEX can render it as a link; a bare prose pointer is tolerated but not linked. |
| `owner:` | scalar string | optional | unset (renders blank) | The accountable **owner-role** for freshness (FR-10). **Free string, not an enum** — see justification below. | If present, non-empty single-line scalar. |
| `audience:` | list of short strings | optional | `[]` | Who the doc is for — drives the INDEX "Audience" filter column (FR-1, FR-10). **Free strings, not a closed enum** — see justification below. | If present, a YAML list of short role labels (e.g. `[architect, pm]`). |
| `approved_at_commit:` | scalar string (git SHA) | **generator-written** | unset on un-migrated/never-approved docs | The commit at which the doc was last approved; the freshness baseline (FR-4/FR-5). Written by `aid-discover`/`aid-update-kb` on approval, **never hand-authored**. | If present, a 7–40 char lowercase hex string. Absence is **valid** (degrade-gracefully: an un-stamped doc is treated as "approval baseline unknown" by f007, not as a lint failure). |

**`owner:`/`audience:` — enum vs free string (decision + justification).** Both are **free
strings**, not closed enums. Rationale, grounded in REQUIREMENTS §1.3 / §3.2: the audience
roster is explicitly open-ended ("junior dev, non-tech PM, senior architect, UX
designer…") and §1.3 makes audience/ownership a *per-project* dimension that a fixed enum
would re-introduce the rejected "project-type catalog" rigidity for. A closed enum would
also force every adopter onto AID's role names. The lint therefore checks *shape* (present
→ non-empty scalar / list of short strings), not *membership*. A project that wants a
controlled vocabulary can add it via the existing `.aid/knowledge/.review-checklist.md`
override hook (already documented in `frontmatter-schema.md` / `review-rubric.md`).

**Updated canonical YAML block** (for `frontmatter-schema.md`'s "Canonical schema" section,
hand-authored doc — note `intent:` is retained during the coexistence window and marked
*superseded*):

```yaml
---
kb-category: primary
source: hand-authored
objective: One-line noun-phrase purpose (INDEX Objective column).
summary: One-sentence scope of this document (INDEX Summary column).
sources:
  - path/or/glob/to/a/source        # files/dirs this doc summarizes
  - https://vendor.example/spec     # external docs count too
  # use `sources: []` only for a pure-synthesis doc with no underlying source
tags: [native-term, subsystem-name]   # optional — concrete project keywords
see_also: [other-doc.md]              # optional — negative-routing pointers
owner: architect                      # optional — accountable owner-role (free string)
audience: [architect, pm]             # optional — who the doc is for (free strings)
approved_at_commit: a1b2c3d           # GENERATOR-WRITTEN on approval; never hand-author
# --- legacy, superseded by objective:/summary:, retained until f011 migration ---
intent: |
  (superseded) One paragraph; kept only during the coexistence window.
contracts: []
changelog:
  - 2026-06-22: Added objective/summary/sources/tags/see_also/owner/audience
---
```

For `source: generated` docs (e.g. INDEX.md itself), `objective:`/`summary:` are
**generator-written** (the generator already emits its own frontmatter — see
`build-kb-index.sh` lines 117–131), so the *hand-authored-required* lint does not apply to
`source: generated` docs (they are validated by the existing Build-Verify rubric instead).

### Field Flow

```
AUTHOR (hand)              PARSE (build-kb-index.sh)         CONSUMERS
objective: ─────────────►  extract_field "objective" ─────► INDEX "Objective" col (f002)
summary:   ─────────────►  extract_field "summary"   ─────► INDEX "Summary" col   (f002)
tags:      ─────────────►  extract_list  "tags"      ─────► INDEX "Tags" col      (f002)
see_also:  ─────────────►  extract_list  "see_also"  ─────► INDEX "See-instead"   (f002)
audience:  ─────────────►  extract_list  "audience"  ─────► INDEX "Audience"      (f002)
sources:   ─────────────►  extract_list  "sources"   ─────► freshness check (f007),
                                                            calibration coverage (f005)
owner:     ─────────────►  (parsed, not in INDEX)     ────► freshness accountability (f007)
approved_at_commit: ◄────  WRITTEN by aid-discover/    ───► freshness baseline (f007)
                            aid-update-kb on approval
```

1. **Author** writes the required + chosen optional fields into each KB doc's frontmatter.
2. **Parse** — `build-kb-index.sh` reads them. The script today has `extract_field`
   (single-line scalar, lines 71–85) and `extract_literal` (multi-line `|` block, lines
   89–114). `objective:`/`summary:` use the **existing** `extract_field` unchanged
   (single-line scalars by design — see schema rules). `tags`/`see_also`/`audience`/
   `sources` need a **new `extract_list` helper** (a YAML inline-or-block list reader)
   added to the script. This is the one net-new parser primitive.
3. **Consumers:**
   - **INDEX (f002)** — `build-kb-index.sh` emits the routing table (Document · Objective ·
     Summary · Tags · See-instead · Audience) instead of today's per-doc `intent:` prose
     blocks (lines 157–193). **This feature delivers the schema + the `extract_*` plumbing
     and the new fields in every template; the INDEX table *rendering* is f002's slice.**
     To keep features decoupled and `kb-hygiene` green at every commit, this feature ships
     a backward-compatible generator: it parses the new fields and continues to emit the
     current INDEX shape, *falling back* `objective`→`intent` when `objective:` is absent
     (coexistence). f002 then flips the emission to the table. (If the orchestrator
     sequences f001+f002 as one delivery, the table lands here directly — **[SPIKE: confirm
     f001/f002 delivery boundary with the plan]**.)
   - **Freshness (f007)** — consumes `sources:` (what changed) + `approved_at_commit:`
     (baseline) per doc. Not built here; this feature only guarantees the fields exist,
     parse, and validate.
   - **Calibration (f005)** — consumes `sources:` as the coverage-vs-source evidence list.
4. **Render to the 5 host trees (GAP-B).** Canonical files changed by this feature
   (`frontmatter-schema.md`, the 14 `knowledge-base/*.md` primary/extension templates
   plus the `meta` `README.md`, `build-kb-index.sh`,
   `review-rubric.md`, `principles.md`) all live under `canonical/` and are emitted by
   `run_generator.py` to: `profiles/claude-code/.claude`, `profiles/codex/.codex`,
   `profiles/cursor/.cursor`, `profiles/copilot-cli/.github`, `profiles/antigravity/.agent`
   (confirmed by `find build-kb-index.sh` → 5 profile copies + the repo's `.claude/`
   working copy). **render-drift stays green** by editing canonical *only* and running
   `python .claude/skills/generate-profile/scripts/run_generator.py` before commit, never
   hand-editing a rendered copy (C3; render-drift job, `test.yml` lines 24–42). The script
   carries no `python3`-version or path assumptions beyond what the existing renderer's
   `rewrite_install_paths` already handles.

### Affected Components

| Component | Path | Change |
|-----------|------|--------|
| Frontmatter schema | `canonical/aid/templates/kb-authoring/frontmatter-schema.md` | Add the 8 field definitions (table above), the updated canonical YAML block, the P6 carve-out note, and the coexistence/migration note for `intent:`. |
| KB-doc templates (14 primary/extension) | `canonical/aid/templates/knowledge-base/*.md` | Add `objective:`/`summary:`/`sources:` (required) + the optional fields to each of the 14 doc templates' frontmatter seed; keep `intent:` during coexistence. Seed `sources: []` only for a genuinely sourceless pure-synthesis/glossary template. **`external-sources.md` is the exception**: it is a registry of external URLs/vendor specs, so its `sources:` are those external docs — seed it with the external URL/registry it summarizes (it is the one template whose `sources:` entries are external URLs rather than repo paths), NOT `sources: []`. The `meta` `README.md` is left as-is (lint skips `meta`). |
| INDEX generator/parser | `canonical/aid/scripts/kb/build-kb-index.sh` | Add `extract_list` helper; parse the new fields; backward-compatible emission with `objective`→`intent` fallback (table emission is f002). |
| Canonical→render generator | `.claude/skills/generate-profile/scripts/run_generator.py` (+ `render_lib.py`) | **No code change expected** — the new content is plain template/script text the existing renderer already carries. Re-run to refresh all 5 profiles + emission manifests. **[SPIKE: verify no per-script render manifest pins the old `build-kb-index.sh` byte-shape; if it does, regen, don't hand-edit.]** |
| Review rubric | `canonical/aid/templates/kb-authoring/review-rubric.md` | Document that the lint **reuses the existing rubric tags** (`[FM-MISSING]` HIGH = required field absent; `[FM-INVALID]` HIGH = malformed shape/value, e.g. `sources:` not a list, `approved_at_commit:` not hex) — **no new tag is introduced** (`[FM-INVALID]`'s "invalid value" semantics already cover shape errors). Note that required new fields are *graded for presence/shape* (carve-out), optional fields stay exempt. |
| Principles | `canonical/aid/templates/kb-authoring/principles.md` | Amend P6: required new fields are NOT exempt (presence/shape lint applies); everything else stays exempt. |
| **NEW field-validation lint** | `canonical/aid/scripts/kb/lint-frontmatter.sh` (proposed name) | Deterministic check, **soft-skip on day one** (skips any doc carrying NONE of the new fields — "pre-migration"; see Validation & Migration): for each non-skipped hand-authored (`source: hand-authored`) primary/extension KB doc, requires non-empty `objective:`, `summary:`, and a well-formed `sources:` (list; each entry a path/glob/URL); optional fields, if present, are well-shaped; `approved_at_commit:`, if present, is hex. ASCII-only bash; emits **existing-rubric** `[FM-MISSING]` (absent required field) / `[FM-INVALID]` (malformed shape/value) findings — no new tag. Becomes a hard gate (all primary/extension docs must comply) only after f011 migrates AID's own docs. |
| CI — kb-hygiene | `.github/workflows/test.yml` (job `kb-hygiene`, lines 98–124) | Add a step running `lint-frontmatter.sh` over `.aid/knowledge/`. **On f001's delivery this stays green because the lint soft-skips all 15 un-migrated docs** (none carry the new fields yet); it only enforces on docs already on the new schema, and becomes a hard gate after f011 (see Validation & Migration). The existing "INDEX.md is fresh" step (lines 116–124) keeps working — it filters timestamps and diffs a regen, format-agnostic, so it stays green across the generator change. |
| CI — canonical suites | `tests/canonical/test-frontmatter-lint.sh` (NEW) + `tests/run-all.sh` glob | A canonical helper suite asserting `lint-frontmatter.sh` flags each failure class (missing required field, malformed `sources:`, bad `approved_at_commit:`) and passes a well-formed fixture. Auto-discovered by `tests/run-all.sh` (glob), run in the `canonical-tests` job (`test.yml` line 80). |
| CI — ascii-only | `tests/canonical/test-ascii-only.sh` (allow-list, lines ~23–46) | **Add the new `lint-frontmatter.sh` to the ASCII allow-list.** (Note: the existing `build-kb-index.sh` is NOT currently in that list — see C2 note below.) |
| render-drift | `test.yml` job `render-drift` (lines 24–42) | No edit; stays green by regenerating profiles after canonical edits. |

### Validation & Migration

**The lint (`lint-frontmatter.sh`) — deterministic checks** (no LLM; CI-able; C5/NFR-3):

- **Presence (required):** for each `source: hand-authored` doc with `kb-category:` in
  `{primary, extension}`, `objective:` and `summary:` are present and non-empty after
  trim, and `sources:` is present as a YAML list (possibly `[]`). Missing → `[FM-MISSING]`
  (HIGH — the **existing** rubric tag for an absent frontmatter field).
- **Shape (well-formedness):** `objective:`/`summary:` are single-line scalars;
  `sources:`/`tags:`/`see_also:`/`audience:` (when present) are lists; each `sources:`
  entry matches a path/glob/URL shape (not a free sentence); `approved_at_commit:` (when
  present) is 7–40 lowercase hex. Violations → `[FM-INVALID]` (HIGH — the **existing**
  rubric tag for "frontmatter field has invalid value," which already covers these shape
  errors; **no new `[FM-MALFORMED]` tag is added**). The lint does NOT resolve paths (that
  is f007) and does NOT grade prose quality (stays exempt).
- **Scope:** `meta` docs and `source: generated` docs are **skipped** by this lint (they
  route to Spot-Check / Build-Verify rubrics, unchanged). This mirrors the existing rubric
  routing in `review-rubric.md`. **Additionally — day-one soft-skip:** any doc carrying
  NONE of the new fields (`objective`/`summary`/`sources`/`tags`/`see_also`/`owner`/
  `audience`) is treated as **pre-migration** and skipped, so the lint cannot red CI on an
  un-migrated KB (see the soft-until-f011 transition below). Required-field checks fire only
  once a doc has adopted any new field.

**The P6 carve-out.** P6 currently states "the entire frontmatter block is exempt from
review." This feature narrows it: the **required new fields are graded for presence and
shape** (mechanically, by the lint — not semantically by the reviewer). Prose *quality* of
`objective:`/`summary:` remains exempt (no reviewer judgment), preserving P8 "rigor follows
value." Legacy fields (`intent`, `contracts`, `changelog`) and the optional new fields stay
fully exempt. This is consistent with P4 ("lint enforces what frontmatter declares").

**Forward-compatibility / degrade-gracefully (NFR-7).** Existing KBs (AID's own + adopters')
lack the new fields until f011 migrates them. Until then:

- `build-kb-index.sh` **falls back** `objective`→`intent` and emits an empty cell for any
  absent optional field, so an un-migrated KB still produces a valid INDEX (the existing
  "INDEX.md is fresh" CI step stays green because the generator is deterministic on
  whatever fields exist). The schema's existing rule "Missing fields are treated as
  default-empty / Unknown fields are tolerated" (frontmatter-schema.md lines 167–168) is
  the contract that makes this safe.
- **The lint is soft-skip on day one (decided; resolves SPIKE-2).** f001's own delivery
  cannot ship a hard lint: **0 of the 15** hand-authored primary/extension docs in
  `.aid/knowledge/` carry `objective:`/`summary:`/`sources:` yet (migration is f011), so a
  hard gate would red CI on this very feature. Therefore the day-one behavior is fixed:
  `lint-frontmatter.sh` **skips any doc that does not yet carry ANY of the new fields**
  (treats it as "pre-migration" — e.g. a doc that still carries `intent:` but no
  `objective:`). It enforces required-field presence/shape **only on docs that already
  declare the new schema** (any new field present). This means f001 can land its own
  template/schema changes with CI green while AID's un-migrated docs are untouched.
- **Soft-until-f011 → hard-after-f011 (the explicit transition).** The lint stays in
  soft-skip mode through f001 and until **f011** migrates AID's own primary docs (writing
  the new fields into all of them). Once f011 lands, the lint is flipped to a **hard gate**
  (every primary/extension doc must comply — the pre-migration skip becomes a no-op because
  no doc is pre-migration anymore). This ordering is mechanical, not a SPIKE: f001 ships
  soft, f011 migrates + flips hard, so CI never half-enforces and never reds on
  un-migrated content in between.
- **`approved_at_commit:` absence handling:** never a lint failure (it is
  generator-written and absent on every doc until first approval post-migration). f007
  treats absence as "baseline unknown → freshness verdict = `unknown` (NOT *suspect*),"
  never as an error — so an un-migrated KB is never falsely flagged. This feature only
  reserves the field name + hex shape.

**Migration (FR-30, deferred to f011).** This feature does **not** migrate existing docs;
it defines the target schema the f011 migration writes. The migration moves `intent:`
content into `objective:`/`summary:` (or retains a derived `summary:`), seeds `sources:`,
and stamps `approved_at_commit:` at migration HEAD — following AID's migration precedent
(`migrate-work-hierarchy.sh`). Retiring `intent:` is f011's job; this feature keeps
`intent:` valid (coexistence) so no doc breaks mid-flight.

### Constraints

- **C2 / Q2 — ASCII-only.** The new `lint-frontmatter.sh` vendors into the install bundles
  (it is a shipped KB script alongside `build-kb-index.sh`), so it MUST be ASCII-only
  (bash; PS-5.1 N/A). It MUST be added to the `test-ascii-only.sh` allow-list. **Observed
  gap to flag to the plan:** the *existing* `build-kb-index.sh` is **not** in that
  allow-list today, so the ASCII guard does not currently cover it — and this feature edits
  it. **[SPIKE: add `build-kb-index.sh` + the new lint to `test-ascii-only.sh`; confirm the
  existing script is already ASCII so adding it does not newly fail CI.]** Any non-ASCII in
  the schema doc / templates is fine (they are markdown, not shipped `.sh`/`.ps1`).
- **C3 / NFR-4 — render-drift green.** Author in `canonical/` only; run
  `run_generator.py`; commit the regenerated `profiles/`. Never hand-edit a rendered copy.
- **C7 — kb-hygiene & INDEX-fresh green.** The "INDEX.md is fresh" step is format-agnostic
  (regen + timestamp-filtered diff), so the generator change keeps it green provided AID's
  own INDEX.md is regenerated and committed in the same change.
- **NFR-8 / C1 — no new runtime.** The lint is plain bash + standard coreutils (`awk`,
  `grep`) — the same toolset `build-kb-index.sh` already uses. No embedding model, binary,
  MCP, or `python3`/`pwsh` escalation.
- **NFR-3 / C5 — determinism.** Both the parser changes and the lint are mechanical,
  ordering-stable (the generator already `sort`s its file list, line 150), and assertable
  in CI via the new canonical suite. No LLM in this feature's path.

### Spikes (genuine unknowns flagged, not guessed)

- **[SPIKE-1]** f001/f002 delivery boundary — does the INDEX *table* render land in this
  feature or f002? Spec assumes f002, with f001 shipping a backward-compatible generator.
  Confirm with the delivery plan.
- **[SPIKE-2 — RESOLVED]** Coexistence enforcement. **Decided: soft-skip on f001, hard
  after f011.** The lint skips any doc carrying none of the new fields (pre-migration), so
  f001 ships with CI green over its 0-of-15 un-migrated docs; f011 migrates AID's own docs
  and flips the lint to a hard gate in the same delivery. See Validation & Migration. (No
  longer a SPIKE — it is a fixed design decision.)
- **[SPIKE-3]** render manifest byte-pinning — verify no emission manifest pins the old
  `build-kb-index.sh` byte-shape such that the generator must be re-run (per the
  render-drift-full-generator precedent); if so, regen, never hand-edit.
- **[SPIKE-4 — failure mode named; deferred to f011/scaffolding]** `aid-config` scaffolding
  (a schema consumer, `frontmatter-schema.md` line 5) writes fresh-KB docs **without** the
  new fields. **Explicit consequence:** such a freshly-scaffolded doc would trip the
  `objective:`/`summary:`/`sources:` lint — EXCEPT that the **day-one soft-skip** (see
  Validation & Migration) covers it: a scaffolded doc carrying none of the new fields is treated as pre-migration
  and skipped, so CI does not red while `aid-config` is unupdated. Updating `aid-config` to
  seed the new required fields is therefore **deferred to f011 / scaffolding scope** (the
  same delivery that migrates AID's own docs and flips the lint hard); it must land before
  the hard-gate flip, or newly-scaffolded docs would fail once the soft-skip is removed.
