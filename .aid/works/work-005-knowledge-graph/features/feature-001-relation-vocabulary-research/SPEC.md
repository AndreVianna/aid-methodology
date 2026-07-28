# Relation Vocabulary Research

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-28 | Feature identified from REQUIREMENTS.md §5.4 (FR-4–FR-6), §8 (D-1), §10 (deliverable 1) | /aid-define |
| 2026-07-28 | Technical specification added | /aid-specify |
| 2026-07-28 | Reconciled with features 003/005 — file ownership corrected to this feature (was feature-003); `endpoint_kinds`/`passes` restated as load-time fail-closed gates rather than consumer-only; `endpoint_kinds` validator open item closed (V12 `[LOW]`) | /aid-specify |
| 2026-07-28 | Gate finding 1 [CRITICAL] fixed — vocabulary carrier realigned to features 003/005: file is now YAML (`relation-vocabulary.yml`, owner decision), parse contract restated as a YAML entry contract, P2a render hazard re-derived for `.yml`, consumer table restated against the entry shape, and the former Markdown sections re-homed | /aid-specify |
| 2026-07-28 | Cross-reference repoint after feature-011's three-way split: the manifest and install wiring and the emission-manifest records are now **feature-012**'s, and the two ship-time Knowledge Base updates (`artifact-schemas.md`, `domain-glossary.md`) are **feature-013**'s. No decision in this SPEC changes | /aid-specify |

## Source

- REQUIREMENTS.md §5.4 (FR-4, FR-5, FR-6)
- REQUIREMENTS.md §8 Assumptions & Dependencies (D-1 — implementation depends on this research completing)
- REQUIREMENTS.md §10 Priority (proposed deliverable 1)
- REQUIREMENTS.md §9 (source of truth for AC-2, which feature-003 validates)

**Dependency position.** This is one of the two RESEARCH features that block implementation.
It blocks feature-003 (the schema cannot validate inverse pairs without the vocabulary) and
feature-005 (the deterministic scan cannot type a row without it). It does **not** block
feature-004, which is pure source enumeration and needs no relation types.

## Description

This is a **RESEARCH feature. Its output is a decision, not shipped code** — a written
vocabulary specification that later features bind to.

Relationships recorded in `relationships.md` must not be free text. Both directions of every
relationship — read source-to-target and read target-to-source — are drawn from a closed,
well-defined set of relation/inverse pairs, so that a machine can check a row and a reader
sees consistent language across the whole table. Nuance that no pair captures belongs in the
row's free-text observation field, never in the relation columns.

This feature establishes that vocabulary through dedicated research. A large vocabulary is
acceptable and expected: comprehensiveness is preferred over brevity, because a vocabulary
too small to name a real relationship forces contributors back into free text and destroys
the closed-set guarantee. Every relation type is also assigned a category, and those
categories become a grouping dimension the graph view can offer the reader.

## User Stories

- As a **maintainer/architect**, I want every relationship in the table to be named from one
  agreed set of terms, so that I can read the whole table without guessing whether two
  differently-worded rows mean the same thing.
- As an **AI agent**, I want the relation types to be a closed enumeration with known
  inverses, so that I can route over `relationships.md` mechanically instead of
  interpreting prose.
- As a **maintainer/architect**, I want relation types grouped into categories, so that I can
  collapse the graph to a category level and see structure rather than a hairball.

## Priority

Must

## Acceptance Criteria

Completion criteria for the research (this feature ships a decision, so its criteria are
deliverables rather than runtime behaviour):

- [ ] A written vocabulary specification exists listing every relation type, each paired with
      its inverse, such that the pairing is total — every type has exactly one inverse, and
      applying the inverse twice returns the original type.
- [ ] Every relation type is assigned to exactly one named category, and the category set is
      documented with a one-line meaning for each.
- [ ] The vocabulary is demonstrably sufficient for the three relationship sources in §5.1:
      for each of KB-to-KB, KB-to-source, and KB-to-external, at least one worked example row
      is shown using only vocabulary terms, with no free-text relation.
- [ ] The specification states, for each relation type, whether it is expected to arise from a
      deterministic scan or only from a reading pass, so that feature-005 knows which types
      its two passes may emit.
- [ ] The specification is recorded in a form feature-003 can bind to as a validation input —
      i.e. the closed set is machine-readable, not only prose.
- [ ] Given the delivered vocabulary, when feature-003 validates a row's two relation columns,
      then AC-2 (valid inverse pair; no row whose two directions disagree) is decidable
      without human judgment.

---

## Technical Specification

> Added by `/aid-specify`. Do not fill during interview.
> The sections below are determined by Specify based on KB, codebase, and developer discussion.

### Data Model

**There is no database, no schema, and no migration.** This feature ships a decision: a written,
machine-loadable vocabulary that later features bind to. What follows specifies the *shape of that
research output*, in the place of the table-and-column model a runtime feature would carry here.

#### The vocabulary record

The delivered vocabulary is a set of records, one per relation type. Each record carries seven
fields, and is expressed as one YAML mapping entry (§ Layers & Components fixes the carrier and its
parse contract). All seven keys are required; an absent or empty value is a defect.

| Key | Meaning | Value rule |
|-----|---------|-----------|
| `relation` | The relation name read Source → Target — the value that may appear in a `relationships.md` `S2T Relation` cell. | Lowercase, hyphen-separated, active-voice verb phrase (`documents`, `depends-on`). Unique across the vocabulary; it is the entry's identifying key. |
| `inverse` | The name of the same relationship read Target → Source — the value that must appear in `T2S Relation` when `S2T Relation` holds `relation`. | Must itself be a `relation` value somewhere in the vocabulary (the set is closed under inversion). |
| `symmetry` | Whether the pair is directionless. | Closed enum: `asymmetric` \| `symmetric`. `symmetric` **iff** `inverse` equals `relation`. |
| `category` | The single grouping bucket this type belongs to (FR-6). | Exactly one value, drawn from the file's own `categories:` set. Never blank, never multi-valued. |
| `endpoint_kinds` | Which ordered pairs of node-id prefixes (§5.3) this relation can legally join. | Non-empty list of `<source-prefix>-><target-prefix>` tokens over `kb:`, `int:`, `ext:` — e.g. `kb:->int:`. |
| `passes` | Which extraction passes (§5.8) may emit this type. | Non-empty subset of `declared`, `derived`, `inferred` — the same three values `Provenance` uses (§5.2). |
| `definition` | What the relation asserts, in one sentence, precise enough that two authors pick the same type for the same fact. | One sentence, on one line. |

`relation` is the **identifying key**, and that choice is not free: feature-005 D3's
`edge-relation-map.yml` names vocabulary pairs "by their `s2t` label", and feature-005 looks `t2s`
up "as the inverse of `s2t` in the vocabulary". So `relation` is the join column the rest of the
work already references, and `inverse` is derived from it rather than being separately addressable.

`endpoint_kinds` and `passes` are not checked by any acceptance criterion in REQUIREMENTS.md §9 —
AC-2 is scoped to vocabulary membership and inverse consistency only. **But they are load-bearing,
not merely informational** *(reconciled 2026-07-28 with features 003 and 005)*: feature-005 consumes
both as **fail-closed gates at map-load time**, which is deliberately before any row exists so that
gating cannot introduce per-row variability and FR-32's byte-reproducibility is preserved. Feature-003
additionally emits an advisory validator finding (`V12`, `[REL-ENDPOINT]`, `[LOW]`, never gating) on a
prefix pair the vocabulary does not list — the one deliberate exception to that validator set's
otherwise-uniform severity, precisely because no acceptance criterion requires it. `passes` also
discharges the fourth completion criterion above (which types each of feature-005's passes may emit).
These
are also the two fields the three-field `pairs:` shape that features 003/005 first specified could
not supply at all, which is why the seven-field entry is the retained shape (owner decision,
2026-07-28).

#### The inverse-pair contract

The `relation` → `inverse` map is an **involution** on the vocabulary: applying it twice returns the
original name. Stated as the properties a self-test asserts:

1. **Closure** — every `inverse` value is present as some entry's `relation` value.
2. **Totality** — every entry has exactly one `inverse`; no entry is missing one.
3. **Involution** — for every entry, `inverse(inverse(relation)) == relation`.
4. **Symmetric consistency** — `symmetry` is `symmetric` exactly when `inverse == relation`, and
   `asymmetric` exactly when it does not. No third case.
5. **Category totality** — every entry carries exactly one `category`, and every `category` used
   appears in the file's `categories:` set with its one-line meaning.

Property 4 is the edge case a naive inverse-pair validator gets wrong. **Symmetric relations are the
fixed points of the involution**, so a validator written as "assert `inverse != relation`" rejects
every legitimate symmetric type, and a validator written as "assert a row's two relation cells
differ" rejects every legitimate symmetric *row*. Both are wrong. The rules are therefore explicit:

- A symmetric relation's entry has `relation == inverse` and `symmetry: symmetric`. This is the case
  feature-003 D4 already permits but leaves untyped ("self-inverse entries (`field1 == field2`) are
  permitted; the loader neither requires nor forbids them"); `symmetry` makes it declared rather than
  merely tolerated, so the loader can assert property 4 instead of guessing.
- A `relationships.md` row typed with a symmetric relation has `S2T Relation == T2S Relation`, and
  that is **valid** under AC-2, not a "both directions disagree" failure.
- For a symmetric relation, `(A,B)` and `(B,A)` are the *same* relationship, so AC-3's duplicate
  check must collapse the unordered endpoint pair. AC-3 already words this as "a forward row plus a
  separate inverse row for the same endpoint pair", which covers it; the symmetric case is called
  out here so feature-003 implements it deliberately rather than discovering it.

Symmetric types are expected to be a small minority, and this repository supplies a real one to fit
against: `infrastructure.md` § "Install Bootstrap and Manifests" records that five install manifests
(`install.sh`, `install.ps1`, `packages/npm/scripts/vendor.js`, `packages/pypi/scripts/vendor.py`,
`release.sh`) "must stay byte-lockstep on that file set" — a mutual obligation with no natural
direction.

#### The category set

FR-6 makes `category` a graph grouping dimension, and FR-13's **Overview** lens collapses the graph
to that level. That fixes the constraints on the set, which the research fills in:

- Total and single-valued (property 5 above).
- Each category documented with a one-line meaning.
- Small enough that grouping by category is a *reduction* — a category set whose size approaches the
  vocabulary size gives the Overview lens nothing to collapse. A large vocabulary is wanted (FR-5);
  a large category set is not.

Two axes are available to the research as a starting proposal, both derived from requirements
already fixed rather than invented: the **relationship-source axis** (§5.1's KB-to-KB, KB-to-source,
KB-to-external) and a **relation-nature axis** (structural containment, dependency/invocation,
generation/derivation, documentation/evidence, mutual-obligation). Which axis (or blend) becomes
`category` is the research's call; the constraints above are what it must satisfy.

One category may additionally be load-bearing downstream. feature-006 D2 needs a named
`coverage_bearing` subset of the vocabulary — "the pairs that mean 'this KB concept describes / is
derived from this artifact'" — and states that if this research "produces a category that already
means exactly this, the subset is that category and nothing further is declared". So a
documentation/evidence-shaped category is worth proposing on those grounds too. Selecting and
enumerating `coverage_bearing` remains feature-006's, not this feature's.

### Feature Flow

The research method, as an ordered sequence. It is all reading, naming, and self-testing — no
product code changes, consistent with the RESEARCH task-type rules at
`.claude/skills/aid-execute/references/task-type-rules.md` § RESEARCH ("No code changes to the
project — research produces documents only").

**Step 1 — Fix the frame.** Read REQUIREMENTS.md §5.1 (the three relationship sources), §5.2 (the
eight-column table the names land in), §5.3 (the three id prefixes), §5.4 (FR-4–FR-6), and §5.8
(which pass may emit what). Read `.aid/knowledge/artifact-schemas.md` and
`.aid/knowledge/authoring-conventions.md` § "Frontmatter Rules" for the relationship-bearing fields
this repository already declares, and `.aid/knowledge/domain-glossary.md` so a relation name does
not collide with an existing Concept Spine term.

**Step 2 — Harvest real relationship instances.** Build the evidence base *before* naming anything,
so the vocabulary is fitted to relationships that actually exist rather than to a taxonomy. Every
row below was verified present on disk in this repository and is a checkable instance:

| Evidence source | Where | Relationship it declares |
|-----------------|-------|--------------------------|
| KB frontmatter `see_also:` | most docs under `.aid/knowledge/` — an optional field per `authoring-conventions.md` § "Frontmatter Rules", surfaced as the `See-instead` column of `INDEX.md` | `kb:` → `kb:` negative-routing pointer |
| KB frontmatter `sources:` | every hand-authored KB doc (e.g. `technology-stack.md`) | `kb:` → `int:` — the doc summarizes those artifacts |
| KB frontmatter `tags:` concern id | e.g. `C3` in `authoring-conventions.md` | `kb:` → `kb:` spine anchoring |
| `CONFIRMED … (search: "…")` citations | e.g. `technology-stack.md` § "Why AID Is Polyglot" citing `VERSION` | `kb:` → `int:` evidence citation |
| Generated-files registry lines | `canonical/aid/templates/generated-files.txt`, `<output-path>\|<build-command>` | `int:` → `int:` generator produces output |
| Emission-manifest records | `profiles/<tool>/emission-manifest.jsonl`, the `src`/`dst` keys documented in `canonical/EMISSION-MANIFEST.md` § "Record Schema" | `int:` → `int:` canonical source renders to install-tree path |
| Script reads a data file | `canonical/aid/scripts/kb/harvest-coined-terms.sh` reading `coined-term-denylist.txt` | `int:` → `int:` reads |
| Script invokes scripts | `tests/run-all.sh` discovering `tests/canonical/test-*.sh` by glob (per `technology-stack.md` § "Test Commands") | `int:` → `int:` invokes |
| Install-manifest lockstep set | the five manifests named in `infrastructure.md` § "Install Bootstrap and Manifests" | `int:` ↔ `int:` mutual lockstep — the **symmetric** candidate |
| External-sources registry | `.aid/knowledge/external-sources.md` § "Sources" — **zero entries in this repository** | `kb:` → `ext:` — exercisable only against the Q4 fixture |

The last row is why the `ext:` branch cannot be fitted against this repository: `external-sources.md`
has no registered entries. Per STATE.md Q4 (Resolved) and REQUIREMENTS.md A-6, the `ext:` relations
are fitted and demonstrated against a **self-built synthetic fixture** — a controlled
external-sources file with both resolvable and deliberately unresolvable keys, built by the test that
uses it and depending on no work-folder contents.

**Step 3 — Cluster and name.** Group the harvested instances, choose the category axis under the
§ Data Model constraints, then name each cluster's pair in the fixed lexical form. Naming is
per-pair, never per-direction: a relation is never admitted without its inverse in the same edit.

**Step 4 — Screen candidates.** A proposed type is admitted only if **both** hold:

1. It is traceable either to a harvested instance (Step 2) or to a §5.1 source class that this
   repository cannot instance (the `ext:` case) — no type is added on speculation alone.
2. No already-admitted type's `definition` covers the same assertion. Where two candidates overlap,
   either merge them or sharpen both definitions until an author cannot reasonably pick either.

Comprehensiveness beats brevity (FR-5), so the bar for *adding* is low — but the bar for adding a
type whose meaning duplicates another is absolute, because two interchangeable types reintroduce
exactly the ambiguity the closed set exists to remove.

**Step 5 — Write the single source.** Author the vocabulary file (§ Layers & Components): the
`pairs:` entries, the `categories:` set, and the header comment block carrying the field contract,
the worked examples, and the addition process.

**Step 6 — Self-test the properties.** Verify closure, totality, involution, symmetric consistency,
and category totality (§ Data Model) by loading the file, not by reading it. This is what makes the
closed set "machine-readable, not only prose" — the fifth completion criterion. The check is small
and deterministic, so it belongs with the other canonical validators rather than in skill prose (KB
`decisions.md` D17 — "only non-trivial, reused, deterministic operations are extracted to
`canonical/aid/scripts/`"); feature-003 owns implementing it, since it owns validation.

**Step 7 — Demonstrate sufficiency.** Produce three worked `relationships.md` rows in the
eight-column shape of §5.2 — one KB-to-KB, one KB-to-source, one KB-to-external — each using only
vocabulary terms in both relation columns and nothing but free-text nuance in `Observation`. The
KB-to-external row uses the Q4 fixture's keys. This discharges the third completion criterion.

**Step 8 — Record and hand off.** Two outputs land in two different places, and the split is not
incidental — see § Layers & Components.

**Consumers.** Who reads the vocabulary, and for what:

| Consumer | Reads | To do what |
|----------|-------|-----------|
| feature-003 | `relation` + `inverse` of every `pairs:` entry, via its own `rel_load_vocabulary` (D4/D9) | Decide AC-2 — `V3` membership on both relation labels, `V4` valid inverse pair — without human judgment. `symmetry` lets `V4` accept a self-inverse pair as declared rather than as a tolerated accident |
| feature-005 | `relation`, `inverse`, `passes`, `endpoint_kinds` — same loader | Resolve `edge-relation-map.yml`'s right-hand `s2t` label to an entry, look `t2s` up as that entry's `inverse` (D3), and bound which types each pass may emit. **`passes` and `endpoint_kinds` are the two fields the original three-field `pairs:` shape could not supply**, and are why the seven-field entry replaced it |
| feature-006 | `relation` + `category` | Evaluate the D2 coverage predicate over its `coverage_bearing` subset — feature-006 selects the members; this feature only supplies the categories they are drawn from |
| feature-007 / feature-008 | `category` | Offer category as a grouping dimension (FR-6) and collapse to it for the Overview lens (FR-13) |
| feature-009 | `category`, `definition` | Group and label the accessible table's peer rendering identically (NFR-3) |

Every consumer reads through **one** loader — feature-003 D9's `rel_load_vocabulary` in
`canonical/aid/scripts/graph/relationship-schema.sh` — never by parsing the file itself. That is
what keeps feature-003 D4's reviewable invariant true: no relation label appears in any `graph/`
script, so a reviewer can prove the vocabulary is opaque data by grepping the script tree for a
label and finding nothing.

### Layers & Components

#### Two outputs, two homes

| Output | Path | Lifetime |
|--------|------|----------|
| The **research report** — options considered, evidence, trade-offs, the recommendation and its rejected alternatives | the path named in the RESEARCH task's `Scope` field, under `.aid/works/work-005-knowledge-graph/` (assigned by `/aid-detail`, per `task-type-rules.md` § RESEARCH "Write findings to the path specified in task Scope") | **transient** — disposable with the work folder |
| The **vocabulary file** — the closed set both the generator and the validator load | `canonical/aid/templates/graph/relation-vocabulary.yml`, plus its five profile renders (below) | **permanent** |

This split is mandatory, not stylistic. `CLAUDE.md` § "Tracking discipline" states that work folders
are transient and that "no permanent artifact — product code, `canonical/` content (or its
`profiles/` render), tests, docs, the Knowledge Base, or these context files — may depend on the
contents of a specific work folder". The vocabulary is loaded at runtime by shipped scripts, so it
cannot live in the work folder; the report is pipeline evidence, so it can.

#### Where the single source lives

Requirement FR-4 plus the fifth completion criterion mean the generator and the validator must read
**one** file. That file has to satisfy the properties below:

- **P1 — Canonical-authored.** It lives under `canonical/` and is rendered to every host profile by
  the existing generator (C-2; `infrastructure.md` § "The Build: Multi-Profile Render"), never
  hand-maintained per profile.
- **P2 — Rendered to every install tree as a runtime-loadable data file.** Precedent verified on
  disk: `canonical/aid/templates/shortcut-catalog.yml` is a machine-consumed YAML data catalog that
  renders to all five install trees (`profiles/claude-code/.claude/aid/templates/shortcut-catalog.yml`
  and its four siblings), and `canonical/aid/templates/settings.yml` is a second `.yml` in the same
  directory. So a YAML data file that a script loads at runtime is an established shape here, in
  exactly the directory this file goes to.
- **P2a — Copied verbatim, because `.yml` is not text-transformed.** *This property is the inverse of
  what it said when this file was specified as Markdown; see § The render-time path rewriter, for
  `.yml` below.* A `.yml` is copied byte-for-byte, so nothing in it is rewritten — and nothing in it
  is *fixed up* either. The consequence that binds: the file must carry **no path that has to resolve
  at runtime**.
- **P3 — One file, both faces.** The machine contract and the human definitions are the *same* file
  — the entries carry the contract, the header comment block carries the definitions and the process
  — so they cannot drift.
- **P4 — Registered in the emission manifests.** Every canonical file emits one record per profile
  (`canonical/EMISSION-MANIFEST.md` § "Record Schema"), and the render-drift gate re-runs the full
  generator and diffs `profiles/` — so the file is added by running the full generator, never by
  hand-editing a profile copy.

**The path is `canonical/aid/templates/graph/relation-vocabulary.yml`** — YAML, per the owner's
2026-07-28 decision, and the same path features 003 and 005 already specify.

**Ownership (reconciled 2026-07-28).** *This* feature creates and authors the file — both its schema
and its contents. Feature-003 owns only the **loader and validation contract** (`rel_load_vocabulary`
plus the cross-entry invariants) and explicitly does not create the file; its Layers row is marked as
not-created-there. Feature-005 D3 consumes the entry through that loader. An earlier draft of this
section had feature-003 creating the file with an empty `pairs:` list and this feature filling it in;
that is superseded — a research feature that owns a vocabulary's schema and content should own its
file. It is a machine-consumed data catalog that drives generation, and
this repository's direct precedent for that is `canonical/aid/templates/shortcut-catalog.yml`,
verified on disk: a `.yml` in this exact directory, described in its own header as the "Single-source
manifest" read by a maintainer build helper and by a skill at runtime, rendering to all five profiles.
`canonical/aid/templates/settings.yml` is the second instance.

Two consequences of YAML rather than Markdown, both deliberate:

- **No frontmatter, and no `lint-frontmatter.sh` exposure.** A `.yml` data file carries no YAML
  frontmatter block, so the toolkit-template frontmatter style (`kb-category:`, `source:`,
  `intent:`, `contracts:`, `changelog:`) that `reviewer-ledger-schema.md` carries does not apply
  here. `shortcut-catalog.yml` likewise carries none — its equivalent metadata is the header comment
  block. The KB-document required set (`objective:` / `summary:` / `sources:`) never applied either:
  this is not a `.aid/knowledge/` document, and the KB index generator selects only top-level
  non-dot `.md` files there (`INDEX.md` frontmatter `contracts:` — "One entry per non-dot,
  non-recursive KB document under .aid/knowledge/").
- **Data and documentation share the file via comments, not sections.** See § What the former
  Markdown sections become below.

**The path is no longer open** — it is fixed by the owner's decision and already written into
feature-003 D4 and feature-005 D3, so this SPEC states it rather than recommending it. What the
decision leaves open, and to whom:

| Left open | Owner | Why it is not settled here |
|-----------|-------|----------------------------|
| Widening `rel_load_vocabulary` from a three-field scalar list to the seven-key entry contract below | feature-003 (D4/D9) | feature-003 owns the loader and its exit codes; this feature owns the file's contents and shape |
| ~~Whether `endpoint_kinds` drives an advisory validator warning, and at what severity~~ — **CLOSED 2026-07-28** | feature-003 | Answered: `V12` `[REL-ENDPOINT]` at `[LOW]`, never gating. Still not required by any acceptance criterion, which is exactly why it is advisory |
| Where the `coverage_bearing` subset lives — a third top-level key in this file, or a sibling file | feature-006 (D2) | feature-006 declares and enumerates the subset and only requires that it be readable "beside the vocabulary"; a `coverage_bearing:` key in this file satisfies that, but the choice is feature-006's |
| Manifest and install wiring for the new file | feature-012 | Mechanical: it follows from running the full generator (P4) |

What binds regardless of any of those is P1–P4 and the one-file rule.

#### The render-time path rewriter, for `.yml`

The Markdown version of this SPEC flagged a P2a hazard: `render_lib.py`'s `rewrite_install_paths`
rewrites `canonical/{scripts,templates,skills,agents,recipes}/…` references per profile, so a worked
example citing an `int:` id such as `int:canonical/aid/scripts/kb/harvest-coined-terms.sh` would be
silently rewritten five different ways. **Re-derived against the renderer for a `.yml`: that hazard
does not apply, and it inverts.**

The mechanism, read rather than assumed. `render.py` declares the transform set and applies it by
suffix:

```python
# Extensions that receive text transforms (substitute_filenames + rewrite_install_paths)
_TEXT_EXTENSIONS = frozenset({
    ".md", ".txt", ".sh", ".ps1", ".mjs", ".js", ".html", ".css", ".py",
})
```

and, in the copy loop, `if src_file.suffix.lower() in _TEXT_EXTENSIONS:` applies
`substitute_filenames` then `rewrite_install_paths`, `else: encoded = src_file.read_bytes()`.
`.yml` is **not** in that set, so a `.yml` takes the `else` branch — a verbatim byte copy. Confirmed
three ways rather than by reading the code alone: the canonical `shortcut-catalog.yml` and its
`claude-code` and `cursor` renders all hash to SHA-256 `ab01dd57…c2a853f7`; the same digest is the
recorded `sha256` on that file's `profiles/claude-code/emission-manifest.jsonl` record; and for
contrast `generated-files.txt` — a `.txt`, so in the set — hashes `5553bf91…` canonical against
`cde02508…` rendered, because its `canonical/scripts/…` build commands really are rewritten to
`.claude/aid/scripts/…`. `shortcut-catalog.yml`'s own header states the rule from the other side:
it "Renders as VERBATIM BYTES … a `.yml` is not in render.py's `_TEXT_EXTENSIONS`".

So the hazard changes shape. It is no longer *"a path in this file may be rewritten unexpectedly"*;
it is now **"a path in this file will never be rewritten, and there is no `canonical/` directory in
an installed profile for it to point at."** `generated-files.txt` depends on the rewrite for exactly
this and documents the dependency in its own header ("PATH CONVENTION: build commands use repo-root
paths under canonical/. The renderer … rewrites those repo-root references at render time"). A `.yml`
gets no such help. The rules that follow:

1. **No entry field may contain an install-relative path.** None does: the seven fields are labels,
   two closed enums, a prefix-token list, and one sentence of prose. This costs nothing.
2. **Worked examples live in comments and are illustrative only.** An `int:canonical/…` id in a
   comment survives verbatim into all five profiles, where that path does not exist. It is never
   resolved by anything — no consumer reads comments — so it is safe, but it must be written as an
   example rather than as an instruction, and preferably drawn from paths that exist in an installed
   tree.
3. **`substitute_filenames` does not run either.** That is the other half of the transform: a
   `{project_context_file}`-style placeholder would survive as literal text rather than resolving per
   profile. The file must therefore use no placeholders.

One benefit worth recording: verbatim copying makes the file **byte-stable across profiles**, so a
vocabulary edit produces exactly six changed files — the canonical source and five identical renders
— plus the five `sha256` updates in the emission manifests, and the render-drift gate compares one
byte-stream against five copies of it. A Markdown carrier would have produced five *different*
rendered bodies, and the property self-test would then have had five variants to be true of.

#### The parse contract

Stated inline because a consumer must satisfy it to act (`authoring-conventions.md` § "Signature
Exception" — a load-bearing operational contract is stated inline, never deferred to a `sources:`
pointer). It is deliberately a **restricted YAML subset**, for a reason § How a loader iterates
below makes concrete.

**File shape.** Exactly two top-level keys, in this order:

```yaml
pairs:
  - relation: documents
    inverse: documented-by
    symmetry: asymmetric
    category: documentation
    endpoint_kinds: ["kb:->int:", "kb:->ext:"]
    passes: [declared, derived]
    definition: "The source KB concept describes the target artifact."

categories:
  - "documentation|A KB concept describes or evidences an artifact."
```

- `pairs:` — a block sequence of block mappings, one entry per relation type. The top-level key name
  is **`pairs:`**, unchanged from feature-003 D4, so widening the entry from a three-field scalar to
  a seven-key mapping does not also move the key the loader looks for. `pairs:` present but empty is
  the seeded pre-authoring state, and stays a fail-closed exit 2 per D4.
- `categories:` — a block sequence of `"<name>|<one-line meaning>"` scalars, pipe-separated in the form
  `.aid/settings.yml` uses for `knowledge.doc_set` and feature-003 D4 already cites. It is the closed
  set every entry's `category` is checked against. Two fields only, so no mapping is warranted. Each
  element is **double-quoted**: a meaning is prose and will eventually contain a colon, and quoting
  also removes any question about the `|` — inside a quoted scalar it is unambiguously the field
  separator and not a YAML block-scalar indicator.

**Entry shape** — exact and non-negotiable, because two independent loaders must agree byte-for-byte:

- Each entry begins with the line `  - relation: <value>` — two spaces, `- `, then the `relation`
  key. `relation` is **always first**; the remaining six keys follow, one per line, indented four
  spaces, in the § Data Model table order (`inverse`, `symmetry`, `category`, `endpoint_kinds`,
  `passes`, `definition`). Fixed key order is what lets a line-oriented loader be total.
- All seven keys are present in every entry. A missing key, an unknown key, a duplicate key, or an
  empty value is malformed → exit 2, never a skipped entry.
- Scalars are plain or double-quoted. `definition` is **always double-quoted**, because a sentence
  reliably contains a colon-space or a comma sooner or later. `endpoint_kinds` tokens are **always
  double-quoted**, because `kb:->int:` contains colons that a plain scalar in flow context cannot
  carry safely. `relation`, `inverse`, `symmetry`, `category` are plain lowercase tokens matching
  `[a-z][a-z0-9-]*`.
- `endpoint_kinds` and `passes` are **flow sequences** (`[a, b]`), on one line, non-empty. Flow form
  is required, not optional: it keeps every key on exactly one physical line, which is the property
  the loader depends on.
- Enums are closed: `symmetry` ∈ {`asymmetric`, `symmetric`}; each `passes` element ∈ {`declared`,
  `derived`, `inferred`}; each `endpoint_kinds` element is `<p>-><p>` with each `<p>` ∈ {`kb:`,
  `int:`, `ext:`}. A value outside its enum is malformed → exit 2.
- No nesting deeper than an entry's scalar/flow values. No anchors, aliases, merge keys, multi-line
  block scalars (`|`, `>`), or multiple documents (`---`). Comments (`#`) and blank lines may appear
  anywhere between entries and are ignored.
- Entries are sorted by `category`, then `relation` — deterministic order, so a vocabulary change
  shows as a readable diff. `categories:` is sorted by name.

**How a loader iterates.** A four-space-indented `key: value` line belongs to the most recent
`  - relation:` line; an entry ends at the next `  - relation:`, at `categories:`, or at end of file.
So iteration is a single forward pass with one flush point, and two loaders written independently
against the rules above read the same seven values for the same entry.

That restriction is deliberate. `read-setting.sh`'s header states this project's position on YAML
explicitly — it "does NOT require a YAML parser binary (yq, python) — uses awk for the simple
flat-section dotted-path lookups that AID actually stores, plus list-valued top-level keys… For
nested or complex YAML, install yq and the script will defer to it." A sequence of mappings is past
what its `lookup_list` handles, and `/aid-graph` must not acquire a `yq` dependency in a project
whose CLI ships zero runtime dependencies. Hence the subset: one key per physical line, fixed order,
flow-only lists — parseable by the same class of small awk state machine `lookup`/`lookup_list`
already are. **This does widen feature-003 D9's `rel_load_vocabulary` beyond a `lookup_list` reuse**,
which is the loader change the owner's decision accepts on behalf of features 003 and 005.

#### What the former Markdown sections become

The Markdown draft of this SPEC gave the file four `##` sections. YAML has no sections, so each is
re-homed explicitly — nothing is dropped:

| Was | Becomes | Why there |
|-----|---------|-----------|
| `## Vocabulary` (the seven-column table) | the `pairs:` block sequence | It is the data |
| `## Categories` (name → meaning table) | the `categories:` block sequence, same file | It is data too, and property 5 checks entries against it, so it must load with them |
| `## Worked Examples` (three §5.2-shaped rows) | the **header comment block**, plus the research report | They are illustration, not data: no consumer reads them, and a Markdown table row cannot be a YAML value without quoting that would make it unreadable. The report is their durable home; the comment keeps them next to what they illustrate |
| `## Adding a Relation` (the process below) | the **header comment block** | Process prose, not data. `shortcut-catalog.yml` sets this precedent exactly: its header comment carries the full per-field contract *and* the process rule that after any edit the maintainer runs the helper "then the FULL `run_generator.py` (never a partial render)" |

The header comment block therefore carries: the seven-key field contract, the enum values, the
worked examples, the addition process, and a pointer naming the consumers. This is what keeps P3
true — one file, both faces — now that the human half cannot be `##` sections.

#### How a proposed addition is reviewed

The vocabulary is closed, so "closed" has to mean something procedurally:

1. A proposal is a change to the single canonical file — never a row in `relationships.md` carrying
   an unlisted term, and never a local override. There is no second place to put one.
2. It arrives as a pair — two entries, or one self-inverse `symmetry: symmetric` entry — with all
   seven keys filled and with at least one real instance it names. The Step 4 screen applies to
   additions forever, not only at first authoring. A new `category` value means a `categories:` entry
   in the same edit, or property 5 fails.
3. It passes the Step 6 property self-test.
4. The **full** profile generator is re-run and the render-drift check passes, so all five profile
   copies and their emission manifests move together (`infrastructure.md` § "The Build:
   Multi-Profile Render").
5. It goes through the project's normal review gate for a canonical edit — a reviewer ledger at
   `.aid/.temp/review-pending/<scope>.md` in the seven-column shape, graded by `grade.sh`
   (`quality-gates.md` § "The Reviewer Ledger").

**Adding is cheap; removing and renaming are not.** Adding a pair leaves every existing
`relationships.md` row valid. Removing or renaming one invalidates rows — but `relationships.md` is
a *generated* artifact (FR-9, and the `--reset` regeneration path in FR-11), so the remedy is
regeneration, not data migration. That asymmetry is the reason FR-5's "comprehensiveness over
brevity" is safe to follow: an over-large vocabulary costs review attention, whereas an over-small
one forces free text into the relation columns and destroys the closed-set guarantee outright.

#### Artifacts to update on adoption

Not this feature's writes — recorded so the obligation is not lost:

| Artifact | Update | Owner |
|----------|--------|-------|
| `.aid/knowledge/artifact-schemas.md` | Add `relationships.md` and the relation-vocabulary contract to the artifact schema set, per that doc's § "Conventions" rule for adding an artifact type ("add a template under `.claude/aid/templates/`, name its producer/consumer skills, and document its required vs optional sections here") | feature-013's ship-time KB update |
| `.aid/knowledge/domain-glossary.md` | Only if the research coins a term that belongs to the Concept Spine; relation names themselves are data values, not spine concepts | feature-013's ship-time KB update |
| `profiles/*/emission-manifest.jsonl` | One record per profile for the new canonical file — produced by running the full generator, never hand-edited | feature-012 |

No entry in `canonical/aid/templates/generated-files.txt` is warranted: that registry lists files
regenerated during `/aid-discover`'s FIX state, and the vocabulary is an authored source file, not a
generated one.
