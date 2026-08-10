# Planning Artifact Skills

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5.3 (roadmap, mvp, backlog rows), FR-1, FR-4 | /aid-define |
| 2026-08-09 | Technical Specification rewritten whole against spec review r1 (24 findings, 3 CRITICAL). §5's retired four-stage item flow rebuilt on the three-stage flow REQUIREMENTS §5.1 fixes, with the transition table, the move rule, the cross-document-write argument and the duplicate-item oracle rebuilt with it; the release drain re-sourced from `backlog.md` per feature-001 §4b; the empty "owns the shape" claim discharged with concrete frontmatter, headings, an item schema and a settled `## MVP` anchor for both documents; the GFM lazy-continuation defect at the `create`-destination table repaired; every verification row given a command, test id or diff that can fail | /aid-specify |
| 2026-08-09 | **Owner decision on Q7 applied** (work `STATE.md` § Cross-phase Q&A): §5's column mapping gains a **release-note-bullet arm**, so the one-off `## Unreleased` migration derives all seven `backlog.md` columns instead of authoring four of them from nothing. Shape (a), *derive-from-shipped* — `Definition & done-condition` = the bullet's text with the done-condition read as *shipped, pending tag*; `Location` = the anchor the bullet already names; `Risk if not done` = *ships untagged / absent from the next release notes*; `Priority` = `P1`. The alternative, exempting migrated rows from the schema, was rejected: it forks the row shape permanently and every later consumer would have to handle two shapes. No other section changes; §3b's item schema is unamended | owner decision / /aid-detail |
| 2026-08-09 | Closed spec review r2 (21 findings, 0 recurred). The five HIGHs were two classes. **Cross-spec citation integrity:** every claim about a sibling spec was re-read against that spec's current text — §3c's misquotation of feature-002's position row, §9's quotation of a sentence feature-002 does not carry, and §4's binding of a §3c that has since been corrected to agree with this spec are all retired, and every cross-spec citation is now a **section anchor** rather than a line range. **Oracle integrity:** AC-5's oracle corrected from V2 to V4; the criteria rebuilt from five to twelve so that §3 — this feature's core deliverable — and §5's item flow, registration, catalog and routing obligations each carry one; §8 gains V27–V28 and an AC→V map, so no verification row is bound to no criterion. Registration adopts REQUIREMENTS **CC-1** (`required`, not `conditional`), **CC-2** (the `create` skill performs it; no feature hand-edits it) and **CC-3** (`update` consumes a routed seed), each referred to rather than restated. `repurpose: true`'s second job, `group`'s "derived" claim, the `aid-ask` uniqueness claim, the `## Contents` entry form, the `Tag`/`ID` derivation rules and the `README.md` Status token were each corrected against disk | /aid-specify |
| 2026-08-10 | **The two `find canonical -iname …` no-template checks corrected during Detail** (§3 lede, §9 *Depends on feature-001*), to `find canonical/aid/templates -type f \( -iname … \)`. `-iname` matches basenames, so the unscoped form returns the six `canonical/skills/aid-{design,create,update}-{roadmap,backlog}` directories **this feature itself creates** — a claim falsified by this feature landing correctly. Swept with the same defect in feature-001 AC-2 and §1a; raised as **Q8** in the work `STATE.md`. §3's lede additionally had its **claim** narrowed from *"no template anywhere under `canonical/`"* to *"no file anywhere under `canonical/aid/templates/`"*: the broader sentence asserted more than any oracle can check and would have been falsified by this feature's own six skill directories | /aid-detail |

## Source

- REQUIREMENTS.md §5.3 (the skill set — roadmap, mvp, backlog rows)
- REQUIREMENTS.md FR-1 (three-verb lifecycle, incl. the region-level rule for populated
  destinations), FR-4 (all three verbs ship together), FR-8, FR-9 (the two destinations
  are conditional documents, created on demand)
- REQUIREMENTS.md **FR-11** — the cross-feature contracts this spec refers to rather than
  restates: CC-1 (resolved doc-set presence is `required`), CC-2 (the `create` skill writes
  the registration; no feature hand-edits it), CC-3 (`update` consumes a seed when one is
  present), CC-4 (the four registration surfaces), CC-5 (a region-owning skill never
  creates its document), CC-9 (confusable-pair ownership)
- REQUIREMENTS.md §9 AC-3a, AC-6, AC-6a, AC-6b, AC-7

## Description

Nine skills covering the three planning artifacts:

| Artifact | `design` | `create` | `update` | Destination |
|----------|----------|----------|----------|-------------|
| roadmap | `/aid-design-roadmap` | `/aid-create-roadmap` | `/aid-update-roadmap` | `roadmap.md` |
| mvp | `/aid-design-mvp` | `/aid-create-mvp` | `/aid-update-mvp` | `roadmap.md` § MVP |
| backlog | `/aid-design-backlog` | `/aid-create-backlog` | `/aid-update-backlog` | `backlog.md` |

These three are grouped as one feature — rather than split per artifact — because they
are the only artifacts that **share a destination document**. `roadmap` and `mvp` both
write `roadmap.md`, so ownership is split by section rather than by document: the MVP is
the first committed slice, the near end of the roadmap and not a peer of it, so
`/aid-*-mvp` owns a named `## MVP` section and `/aid-*-roadmap` owns the remainder and
must not overwrite it. Getting that split right is the substance of this feature, and it
cannot be verified by working on either artifact alone.

`backlog` joins them because it is the other half of the planning lifecycle — the roadmap
states direction, the backlog holds the defined, prioritized items that realize it — and
because the same `design → create → update` contract governs all three. Note that items
do **not** flow from `backlog.md` into `roadmap.md`: the roadmap works at a coarser
granularity, so an item never sits in it (REQUIREMENTS §5.1).

Each skill binds the shared contract rather than restating it. The `design` verb develops
the artifact in `.aid/design/` and never touches the KB; `create` consumes the seed and
writes the destination document plus whatever other output the user asks for; `update`
maintains the document and any previously created outputs, asking the user every run
which those are — and consuming the seed itself when a routed `create` left one behind
(REQUIREMENTS CC-3).

## User Stories

- As an **adopter**, I want to develop a roadmap in `.aid/design/` and iterate on it
  before anything is committed, so that half-formed direction does not reach the KB.
- As an **adopter**, I want to draw the MVP line as a distinct act from planning the
  whole roadmap, so that the first shippable slice gets its own attention.
- As an **adopter**, I want a defined-and-prioritized backlog that outlives any single
  work folder, so that decided-but-unscheduled items are not lost.

## Priority

Must

## Acceptance Criteria

Every criterion names the §8 row that fails when it is not met, and §8 closes with the
map in the other direction, so no verification row is bound to no criterion.

- [ ] **AC-1 — The three-verb sequence completes, per artifact.** Given each of roadmap,
      mvp, and backlog, when the three verbs are run in sequence, then a `.aid/design/`
      seed is produced, then the destination document, then a revision of it — with the
      seed consumed at `create`. **For `mvp` the sequence runs against a `roadmap.md`
      that already exists**, because `/aid-*-mvp` owns a section rather than a document
      (§4, §6b; REQUIREMENTS CC-5); `/aid-create-mvp` against an absent `roadmap.md`
      routes rather than stopping.
      *Oracles:* V5 (the seed is consumed), V15 (the destination document appears — both
      documents), V27 (the revision), V16 (the standalone mvp case).
- [ ] **AC-2 — `## MVP` survives its neighbour.** Given `roadmap.md` contains an `## MVP`
      section, when `/aid-create-roadmap` or `/aid-update-roadmap` runs, then that section
      is left intact. *Oracle:* V7.
- [ ] **AC-3 — `/aid-*-mvp` writes only its section.** Given `/aid-create-mvp` or
      `/aid-update-mvp` runs, when it writes `roadmap.md`, then it writes only the
      `## MVP` section — including leaving the `## Contents` index alone, which holds
      because §3c has `## Contents` carry the `MVP` entry from creation.
      (`/aid-design-mvp` writes no KB document at all — only within `.aid/design/`, per
      FR-1.) *Oracle:* V8.
- [ ] **AC-4 — `update` asks every run and leaves no metadata.** Given any `update` skill
      in this group, when it runs, then it asks the user which derived documents to
      update, and writes no tracking metadata into any output (FR-8). *Oracles:* V21
      (asked every run), V22 (no tracking metadata).
- [ ] **AC-5 — `design` never reaches the KB.** Given any `design` skill in this group,
      when it runs, then it writes only within `.aid/design/` and does not modify
      `.aid/knowledge/`. *Oracle:* V4.
- [ ] **AC-6 — Both documents carry the shape §3 fixes, not one the skill invented.**
      Given all three `create` skills have run on a project with no prior instance — first
      `/aid-create-roadmap` and `/aid-create-backlog`, then `/aid-create-mvp` — then each
      destination carries §3's frontmatter field set and values, §3a/§3b's heading set in
      order, the `## Contents` index in the house link form, the `## MVP` anchor at §3c's
      position, `backlog.md`'s `## Gotchas`, and no C-3-forbidden construct. The
      intermediate state — after `/aid-create-roadmap` alone — carries the forward index
      entry with no `## MVP` heading, which §3c settles and V10 asserts. This is the
      criterion §3 exists to make checkable: with no template on disk, an unstated shape is
      a shape each skill invents.
      *Oracles:* V9 (`roadmap.md`'s heading order, anchor position and index form),
      V15 (`backlog.md`'s heading set, and both documents' existence), V10 (the forward
      index entry), V11 (frontmatter), V12 (C-3), V13 (durable citations in `Location`
      cells), V14 (the C7 `## Gotchas` obligation).
- [ ] **AC-7 — Creation registers the document, and nothing else registers it.** Given a
      `create` skill creates its document, then in the same run it appends the
      `knowledge.doc_set` entry and the `README.md` Completeness row §6b specifies, with
      presence **`required`** (REQUIREMENTS CC-1); and given a project that has never run
      a `create` skill in this group, then neither document nor either registration
      exists. No other skill and no sibling feature writes those entries (CC-2).
      *Oracles:* V15 (both documents, both surfaces, the exact entry strings), V24
      (absent stays absent, and `create` is the sole producer).
- [ ] **AC-8 — An item lives in exactly one of the three documents.** Given the
      `tech-debt.md → backlog.md → release-tracking.md` flow of §5, then no id appears in
      two of them at once, no item id appears in `roadmap.md` at all, and the release
      drain removes from `backlog.md` what it adds to `release-tracking.md`.
      *Oracles:* V18 (the set intersection), V20 (no id in `roadmap.md`), V19 (the drain).
- [ ] **AC-9 — Nine skills, nine complete rows, hand-authored, rendered.** Nine
      directories under `canonical/skills/` and nine rows in the canonical catalog, each
      row carrying all eight fields; re-running `build-shortcut-skills.py` overwrites no
      body; the full render is byte-identical across the five profiles; and no
      count-bearing statement about the catalog is left stale.
      *Oracles:* V1 (directories and rows), V3 (row fields), V2 (hand-authored bodies
      survive the helper), V26 (render parity), V28 (the catalog's own count comments).
- [ ] **AC-10 — No run halts with nothing offered, and nothing is written on the way
      out.** Given any of the nine skills is invoked in a state its own region does not
      admit, then it writes nothing and it ends by naming the specific next act — the
      **skill that can act** where another skill owns the case (destination document
      absent, owned region already populated), or the **unresolved content and the
      override** where the block is the seed's own readiness gate, which no other skill can
      clear. A silent stop, or a stop that names neither, is the failure.
      *Oracles:* V6 (the readiness gate — refuses, seed and destination untouched),
      V16 (`/aid-create-mvp` with no `roadmap.md` — names `/aid-create-roadmap`),
      V17 (each `update` with an absent destination — names the document's owner).
- [ ] **AC-11 — `phase:` is not driven (C-1, NFR-3).** Given any of the nine skills runs,
      then the work it allocates carries no `phase:` value and the closed enum is
      untouched. *Oracle:* V23.
- [ ] **AC-12 — Every description carries its negative route (NFR-4, REQUIREMENTS AC-8).**
      For each of the nine skills, the frontmatter `description` names every neighbour
      §6d assigns it. *Oracle:* V25.

---

## Technical Specification

> **Section applicability.** Data Model, Feature Flow, and Layers & Components assume a
> code project. This feature authors nine hand-authored skills **and fixes the on-disk
> shape of two Knowledge Base documents that have no template**, so those three sections
> are **N/A** and no conditional section auto-activates. §3 (document shape) carries what
> a Data Model section would; §6 (per-skill behavior) stands in for Feature Flow; §4
> (region ownership) and §5 (item flow) carry the cross-document contracts.

### 1. Skill inventory and catalog rows

Nine directories under `canonical/skills/` and nine rows appended to
`canonical/aid/templates/shortcut-catalog.yml` — **the canonical source**. The five
per-profile copies (`.claude/aid/templates/shortcut-catalog.yml` and its four siblings)
are rendered from it as verbatim bytes — the catalog's own header says so at
`canonical/aid/templates/shortcut-catalog.yml:11-12` (*"Renders as VERBATIM BYTES to
`<root>/aid/templates/shortcut-catalog.yml` in all 5 profiles"*) — so a row added under
`.claude/` is discarded by the next render. REQUIREMENTS C-5 fixes the order after any
catalog edit: `build-shortcut-skills.py`, then the **full** `run_generator.py`.

**The nine rows, with every field feature-002 §3f requires.** `alias_of: null` and
`repurpose: true` are uniform across all nine and are therefore stated once here rather
than repeated per row:

| `name` | `verb` | `artifact` | `default_type` | `group` | `intent` |
|--------|--------|------------|----------------|---------|----------|
| `aid-design-roadmap` | `design` | `roadmap` | `DESIGN` | `G3` | "Develop the project's direction as a design seed -- committed vs. wanted, and the sequencing rationale; writes no KB document." |
| `aid-create-roadmap` | `create` | `roadmap` | `DOCUMENT` | `G4` | "Realize a roadmap seed into roadmap.md, creating the document on first use; leaves the MVP section to /aid-create-mvp." |
| `aid-update-roadmap` | `update` | `roadmap` | `DOCUMENT` | `G5` | "Revise roadmap.md's direction entries outside the MVP section, plus any previously created outputs." |
| `aid-design-mvp` | `design` | `mvp` | `DESIGN` | `G3` | "Draw the MVP line as a design seed -- what is in the first shippable slice, what defers, and why each cut was made." |
| `aid-create-mvp` | `create` | `mvp` | `DOCUMENT` | `G4` | "Realize an MVP seed into roadmap.md's MVP section only; the roadmap document itself is /aid-create-roadmap's to create." |
| `aid-update-mvp` | `update` | `mvp` | `DOCUMENT` | `G5` | "Revise roadmap.md's MVP section only, plus any previously created outputs." |
| `aid-design-backlog` | `design` | `backlog` | `DESIGN` | `G3` | "Develop the defined-and-prioritized item set as a design seed, including which tech-debt.md rows to accept into the plan." |
| `aid-create-backlog` | `create` | `backlog` | `DOCUMENT` | `G4` | "Realize a backlog seed into backlog.md, creating the document on first use and moving accepted items out of tech-debt.md." |
| `aid-update-backlog` | `update` | `backlog` | `DOCUMENT` | `G5` | "Revise backlog.md -- re-prioritize, add items, and promote accepted tech-debt.md rows -- plus any previously created outputs." |

**The `intent` strings carry no markdown.** The catalog specifies the field as *"a
one-line human-readable summary of what this shortcut does"*
(`canonical/aid/templates/shortcut-catalog.yml:102-103`) and no live row formats it: a
grep for a backtick inside an `intent:` value over all 58 rows returns `0`. Filenames and
skill names are therefore written bare above, and the em-dashes are ASCII `--`, as the
live rows write them.

**`default_type` and `group` are two different axes, and only the first has a
document-producing precedent to match.**

- **`default_type: DOCUMENT`** is the value the catalog already assigns to every row whose
  product is a document — `aid-create-document`, `aid-update-document` and
  `aid-create-diagram` (`shortcut-catalog.yml:459-482`) — and the closed 8-enum
  (`RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE`,
  `:89`) offers nothing closer for "author a Knowledge Base document". `DESIGN` on the
  three `design` rows matches the shipped `aid-design` row (`:441-448`).
- **`group` is the activity family, chosen — not derived.** Those same three
  document-producing rows carry `group: G8` (`:464`, `:472`, `:480`), so a reader
  comparing them will ask why these nine do not. The answer is on disk in G8's own header:
  the Document family is *"Producer aid-tech-writer, verifier aid-reviewer; …
  **NEVER writes `.aid/knowledge/`** (that is aid-update-kb's territory)"*
  (`shortcut-catalog.yml:450-458`). These nine skills exist precisely to write
  `.aid/knowledge/`, so G8 membership would contradict the family's stated contract. They
  take the family their verb names instead: `G3` Prototype + Design (`:418`), `G4` Create
  (`:145`), `G5` Change + Refactor (`:233`) — the same assignment sibling feature-004 §1a
  makes for its twelve rows. `group` is organizational metadata (`:98-100`); the published
  index derives its families from `verb`, not from `group` (feature-004 §1b), so the
  choice moves no card between sections.

**`repurpose: true` does exactly one job**, and the previous draft claimed a second it
does not do. The catalog defines it as *"`true` for rows whose `SKILL.md` is hand-authored
rather than generated. The maintainer build helper (`build-shortcut-skills.py`) SKIPS
`repurpose: true` rows -- it never generates or overwrites their `SKILL.md`"*
(`:105-109`). It says nothing about the shortcut engine, and the disk refutes the stronger
claim: `aid-deploy` (`:617-624`) and `aid-monitor` (`:625-632`) are both `repurpose: true`
and both reference `shortcut-engine.md` in their hand-authored bodies
(`grep -rln 'shortcut-engine' canonical/skills/` lists `aid-deploy/SKILL.md` and
`aid-monitor/SKILL.md`; it does **not** list `aid-update-dashboard`, which is a generated
doorway and carries no `repurpose` key). **Engine participation
is a property of the body, not of the key** — so these nine bodies simply do not consult
the engine, and V2 is the oracle for the key while V3's field check is the oracle for the
row.

The precedent for a hand-authored row outside the `create`/`update` grid is broad, not
singular: of the 24 live `repurpose: true` rows, **21 sit on a verb other than `create` or
`update`** — `test` (4), `document` (8), `prototype` (2), `design`, `report`, `review`,
`research`, `deploy`, `monitor`, `query` — derived with
`awk '/^  - name: /{n=$3} /^    verb: /{v=$2} /^    repurpose: true$/{print n, v}'` over
the catalog. The previous draft's claim that `aid-ask` is "the one existing
`repurpose: true` row on a non-grid verb" was wrong by twenty.

Destinations, restated as reads and writes. The registration surfaces (§6b) are write
targets too, so they appear here rather than only in §6b — and they bind the two
document-owning `create` skills only, because `/aid-create-mvp` never creates a document
(REQUIREMENTS CC-5) and therefore never registers one:

| Skill | Reads | Writes |
|-------|-------|--------|
| `aid-design-roadmap` | its seed if present, KB, project source | `.aid/design/roadmap.md` **only** |
| `aid-create-roadmap` | `.aid/design/roadmap.md`, KB | `.aid/knowledge/roadmap.md` — everything except `## MVP`; **on creation only**, the `.aid/settings.yml` `knowledge.doc_set` entry and the `.aid/knowledge/README.md` Completeness row + count (§6b) |
| `aid-update-roadmap` | `roadmap.md`, its seed if present, prior outputs | same region + those outputs |
| `aid-design-mvp` | its seed if present, KB, project source | `.aid/design/mvp.md` **only** |
| `aid-create-mvp` | `.aid/design/mvp.md`, `roadmap.md` | `roadmap.md`'s `## MVP` section **only** — never a registration entry, because it never creates a document |
| `aid-update-mvp` | `roadmap.md`, its seed if present, prior outputs | `## MVP` **only** + those outputs |
| `aid-design-backlog` | its seed if present, KB (incl. `tech-debt.md`), project source | `.aid/design/backlog.md` **only** |
| `aid-create-backlog` | `.aid/design/backlog.md`, `tech-debt.md` | `.aid/knowledge/backlog.md` + accepted-row deletions in `tech-debt.md` (§5); **on creation only**, the same two registration surfaces |
| `aid-update-backlog` | `backlog.md`, `tech-debt.md`, its seed if present, prior outputs | same two + those outputs |

### 2. Why these three are one feature

They are the **only** artifacts in this work that share a destination document.
`roadmap` and `mvp` both write `.aid/knowledge/roadmap.md`, so ownership splits by
section rather than by document; `backlog` joins them because §3 fixes the shape of both
new documents at once and §5's item flow terminates in the release drain that
`backlog.md` — not `roadmap.md` — feeds.

The section-ownership split (§4) cannot be verified by working on either artifact alone:
a test that `/aid-create-roadmap` preserves `## MVP` requires `/aid-create-mvp` to have
written it first. Splitting per artifact would defer that verification to integration.

### 3. The documents' shape — this feature's core deliverable

**Why this section exists.** Neither document has a file anywhere under
`canonical/aid/templates/` — the only place a template can live, and the tree the four
seed-counting oracles glob — and that absence is deliberate: it is the mechanism by which the
canonical seed stays at 14 (REQUIREMENTS AC-3; feature-001 §1a). The claim is stated at the
template tree rather than at `canonical/` as a whole because that is what an oracle can check
and what feature-001 §1a itself claims; this feature legitimately adds six directories under
`canonical/skills/`, and a claim about all of `canonical/` would be false the moment it did.
Verified rather than assumed —
`find canonical/aid/templates -type f \( -iname '*roadmap*' -o -iname '*backlog*' \)`
returns nothing. The scope matters: an unscoped `find canonical …` matches basenames, so it
returns the six `canonical/skills/aid-{design,create,update}-{roadmap,backlog}` directories
**this feature itself creates** — it would report a template that does not exist and would
be falsified by this feature landing correctly. So nothing on
disk supplies frontmatter, headings, or an item schema, and if this feature does not
state them, `/aid-create-roadmap` and `/aid-create-backlog` will each invent their own.
feature-001 owns membership and doctrine (§1b's four registration surfaces); this feature
owns **shape and creation, including this repository's own instances** (feature-001 §3b,
§1e).

The worked precedents are on disk, and both are followed rather than paraphrased:
`.aid/knowledge/decisions.md` (the D-concern conditional doc — frontmatter, `## Contents`,
a summary table, then `## D<N> — Title` entries with `**What:** / **Why:** / **Rejected:**
/ **Status:**` fields at `:99-109`) and `.aid/knowledge/tech-debt.md` (the C7 doc — an
ID-keyed inventory table whose header is
`| ID | Type | Description | Location | Risk | Effort | Priority |` at `:73`).

**3a. `roadmap.md`.** Concern **D**, per feature-001 §3a.

Frontmatter — the required set is `kb-category`, `source`, `objective`, `summary`,
`sources` (`frontmatter-schema.md` § Canonical schema; `lint-frontmatter.sh` grades
presence and shape for `kb-category ∈ {primary, extension}` with `source: != generated`):

```yaml
---
kb-category: primary
source: hand-authored
objective: Present commitment and future direction for {project} — what it has decided to do next, why, and what it deliberately did not choose.
summary: Read this to know where the project is going and what the first committed slice is; specific defined-and-prioritized items live in backlog.md and shipped work in release-tracking.md.
sources: []
tags: [D, roadmap, commitment, direction, mvp]
see_also: [backlog.md, decisions.md, release-tracking.md]
owner: architect
audience: [architect, pm, developer]
---
```

Three of those values are decisions, not defaults:

- **`kb-category: primary`**, not `extension`, and this is the one value that goes against
  a local precedent — so the counter-evidence is stated rather than omitted.
  `grep -H '^kb-category:' .aid/knowledge/*.md` returns 16 `primary`, 3 `extension`
  (`decisions.md`, `quality-gates.md`, `release-tracking.md`), 3 `meta`. The three
  `extension` docs are the closest in kind, and `decisions.md` is the precedent
  feature-001 §1a names — but all three are *declared doc-set members* in
  `.aid/settings.yml`, while `frontmatter-schema.md` § `kb-category:` defines `extension`
  as *"outside the project's declared doc-set"*. So the local classification is already
  inconsistent with the schema, and copying it would import that inconsistency.
  The deciding consequence is the rubric: **Extension-Scope** applies cross-doc
  consistency *"against other extensions of the same project, not against the canonical
  16"* (`review-rubric.md:185-193`). `backlog.md`'s central invariant — no item in both it
  and `tech-debt.md` (§5) — is a consistency rule against a **canonical** doc, and
  `extension` would put it outside the reviewer's frame. `roadmap.md` takes the same value
  so the two do not sit in different frames. Counted against the counterexamples: five of
  the sixteen `primary` docs here are **not** among the 14 canonical templates
  (`INDEX.md`, `artifact-schemas.md`, `authoring-conventions.md`,
  `capability-inventory.md`, `relationships.md`), so `primary` on a non-seed doc is an
  established combination in this KB, not a novel one.
- **`source: hand-authored`**, not `forward-authored` — and this is a deliberate
  divergence from the sibling feature, recorded rather than left for a reviewer to find.
  feature-004 §7a sets `source: forward-authored` on every document **its** `create`
  skills create, with `sources: []`, and makes it an acceptance oracle (its V19). The same
  act, the opposite value, so the reason has to be stated.

  `forward-authored` is defined as *"Authored from intent before code exists (the
  greenfield KB seed) … The doc is design-authoritative (design->code) … code->design
  divergence is detected by … [the] separate conformance check"*
  (`frontmatter-schema.md` § `source:`), which routes the doc into `/aid-housekeep`'s
  Conformance Lane (feature-004 §9). That value earns its keep for feature-004's
  destinations: `architecture.md`, `technology-stack.md`, `test-landscape.md` and
  `infrastructure.md` all describe things **code realizes**, so there is a real as-built
  counterpart for the lane to compare the design against. `roadmap.md` and `backlog.md`
  have none — no code realizes a direction entry or an unshipped item — so the lane would
  compare them against nothing, and `design-authoritative over code` would be an authority
  claim over a thing that does not exist.

  The local precedent points the same way: **`decisions.md`, the D-concern conditional doc
  this whole section follows, is `source: hand-authored`** (`.aid/knowledge/decisions.md`
  frontmatter), and `grep -h '^source:' .aid/knowledge/*.md | sort | uniq -c` returns
  **no `forward-authored` document at all** across the 22 — 17 `hand-authored`, 5
  `generated`. Neither new document is a seed member (FR-9), so "the greenfield KB seed"
  does not describe them either.

  *The cost of `hand-authored`, checked rather than assumed.* It routes the doc to
  KB-DELTA's Tier-2 doc←code lane (`state-kb-delta.md` § Conformance Lane's routing
  table), which would be wrong if that lane could rewrite a roadmap from code. It cannot:
  the lane is driven by `sources:` drift (`state-kb-delta.md:90`, `:96` — `suspect` and
  `current` are both defined over a doc's declared `sources:`), and `sources: []` gives it
  no anchor to drift from. So the value costs nothing here and the divergence is confined
  to a difference in the destinations, not a difference in doctrine.
- **`sources: []`**, explicitly. The schema permits the empty list only for a
  pure-synthesis doc, which is exactly what a roadmap is; the consequence is that per-doc
  freshness (f007) has no source to call it stale from, which is correct for a document
  about the future.

Note the two `owner` axes do not collide: the frontmatter `owner:` is the
freshness-accountable **role** (`architect`), while the doc-set row's field 2 is
`skill-self` (§6b) — the producer axis (`doc-set-resolve.md:32-36` § Field grammar,
field 2).

Body layout — frontmatter, title, index, content sections, per the layout convention
(`frontmatter-schema.md` § Doc layout convention). The index heading is `## Contents`, the
form 16 of this KB's 22 docs use (`grep -l '^## Contents$' .aid/knowledge/*.md | wc -l`
→ 16 of 22):

    # Roadmap
    <one-paragraph preamble: what this doc holds and what it does not — no items live here>

    ## Contents          <- the four entries below, in this order
    ## MVP               <- owned by /aid-*-mvp (§4); absent until /aid-create-mvp runs
    ## Now               <- committed, in flight
    ## Next              <- committed, not started
    ## Later             <- direction, not yet committed

**The index entry form is fixed, not left to the author**, because §8 V10 greps for it and
a check that turns on an unstated authoring choice is not a check. Each entry is the
house form this KB already uses — a markdown link whose target is the GitHub-style slug of
the heading, one per line, in heading order (`.aid/knowledge/tech-debt.md` § Contents:
`- [Debt Inventory](#debt-inventory)`; `.aid/knowledge/decisions.md` § Contents uses the
same form for every `## D<N>` entry). For `roadmap.md` that is exactly:

    - [MVP](#mvp)
    - [Now](#now)
    - [Next](#next)
    - [Later](#later)

A bare list (`- MVP`) satisfies the layout convention and would make V10 vacuous, so it is
excluded here rather than discovered during implementation. `backlog.md` (§3b) takes the
same form over its own three sections.

**Entry schema** (level 3, so an entry belongs to its horizon section under the extent
rule in §4). One entry per direction, mirroring `decisions.md:99-109` field-for-field
because the D depth standard demands exactly these five things — *what was decided, why,
the alternatives rejected with the reason each was rejected, status, and evidence*
(`document-expectations.md:239-251`):

    ### <Direction, as a noun phrase>

    - **What:** the direction committed to, at roadmap altitude.
    - **Why:** the constraint or trade-off that drove it.
    - **Rejected:** each alternative considered, with the reason it lost.
    - **Status:** Accepted | Superseded by <entry> -- followed by a durable evidence
      anchor (a path plus a grep-recoverable heading or search string), or the literal
      `intent` when nothing has been built yet.

**No summary table.** `decisions.md` carries one; this document does not. A second
surface listing every entry would have to be kept in step by every `update` run, and the
horizon sections already index the entries. One surface, no drift.

**No item ids anywhere in this document.** Roadmap entries are keyed by title only. That
is what makes §5's duplicate-item oracle well defined and what keeps the coarser
granularity REQUIREMENTS §5.1 requires observable rather than merely asserted.

**3b. `backlog.md`.** Concern **C7**, per feature-001 §3a. `kb-category`, `source` and
`sources` take the same three values for the same three reasons as §3a.

```yaml
---
kb-category: primary
source: hand-authored
objective: Defined and prioritized work items for {project} that have not shipped — the slice committed to the next release and the prioritized remainder.
summary: Read this to see what is accepted into the plan but not yet shipped; raw unscheduled observations live in tech-debt.md and shipped work in release-tracking.md.
sources: []
tags: [C7, backlog, prioritization, items, planning]
see_also: [tech-debt.md, release-tracking.md, roadmap.md]
owner: architect
audience: [developer, architect, pm]
---
```

Body:

    # Backlog
    <one-paragraph preamble: accepted-into-the-plan items only; the promotion criterion>

    ## Contents
    ## Next Release      <- the committed slice; the section release-aid drains (§5)
    ## Prioritized       <- accepted, not yet committed to a tag
    ## Gotchas           <- required by C7 ownership; see below

**Item schema — one ID-keyed table per item section**, modeled on `tech-debt.md:73`'s
seven-column inventory and carrying every field the C7 depth standard demands (*severity
classification, location, risk-if-unaddressed, resolution note*,
`document-expectations.md:192-203`):

| Column | Content | Rule |
|--------|---------|------|
| `ID` | The item's identifier | **Carried unchanged from `tech-debt.md` on promotion** (the minting rule is below). Never re-minted, never reused |
| `Tag` | `[NEW]` \| `[CHANGE]` \| `[FIX]` | The release-note tag `release-tracking.md`'s own body rule requires of every item (`.aid/knowledge/release-tracking.md:17-22`), so the drain re-tags nothing. Its value is **decided at the confirm gate**, seeded by the rule below |
| `Title` | One noun phrase | The key the drain matches on, since release-note bullets carry no id |
| `Definition & done-condition` | What is to be done and what makes it done | The C7 "resolution note"; a row without it is not promotable |
| `Location` | Where the change lands | A **durable anchor** — path plus a grep-recoverable symbol or heading, never `path:LINE`. `kb-citation-lint.sh` runs over `.aid/knowledge/` and exits 1 on the bare-line form |
| `Risk if not done` | The consequence of leaving it | The C7 "risk-if-unaddressed" |
| `Priority` | `P1` \| `P2` \| `P3` | The vocabulary `tech-debt.md`'s inventory already uses (canonical template `:46` — `{P1/P2/P3}`); the C7 severity classification |

**`ID` — where a value comes from, in both directions.** On promotion the id is carried
verbatim, which is what makes §5's duplicate-item oracle (V18) well defined. For an item
**born in the backlog**, the id is minted in **whatever form the project's own
`tech-debt.md` inventory already uses**, taking the next unused ordinal in that form —
`TD-<NNN>` for a project on the shipped template
(`canonical/aid/templates/knowledge-base/tech-debt.md:46`), `W<series>-<ordinal>` in this
repository's own instance. The form is read off the destination, never imposed: the two
documents share one id space, so an id minted in a second form would make V18's `comm` a
comparison of unlike things. Retired ids are never reused and never renumbered —
`.aid/knowledge/tech-debt.md`'s closing prose states the rule and the consequence it
protects: *"IDs are not renumbered, so the gap at `W1-4` is expected and any outside
reference to it still resolves through history"*.

**`Tag` — seeded from the row, then confirmed; never left unset.**
`release-tracking.md`'s body rule fixes the vocabulary and its meaning: `[NEW]` items
*"lead with a feature name"*, `[CHANGE]` and `[FIX]` are *"description-only"*
(`.aid/knowledge/release-tracking.md:17-22`). The tag answers *what does shipping this do
to the released surface* — adds something that did not exist (`[NEW]`), alters something
that did (`[CHANGE]`), or corrects something broken (`[FIX]`). On a promotion the default
is proposed from the promoted row's `Type` cell wherever the project's `Type` vocabulary
determines it — a defect Type seeds `[FIX]`, a gap or absent-capability Type seeds
`[NEW]`, a Type naming an alteration of existing behavior seeds `[CHANGE]`; the shipped
template's own vocabulary (`{Complexity / Test Gap / Outdated Dep / Architecture /
Other}`, template `:46`) leaves several of those undetermined, and an item **born in the
backlog** has no `Type` at all. In every undetermined case the tag is **asked**, at the
same per-item confirm gate that authorizes the promotion (§5). A proposed default is
always presented for confirmation rather than written silently, and no row is written with
an empty `Tag`.

**`Effort` is dropped; `Type` is consumed, not dropped.** Effort is a scheduling estimate
that goes stale between the acceptance decision and the tag, so it does not cross. `Type`
does not survive as a column — it classifies a defect, and `backlog.md` holds accepted
work rather than diagnoses — but it is **read** during the move to seed `Tag`, which is
why §5's column mapping shows it feeding `Tag` rather than being discarded.

**`## Gotchas` is not optional, and the reason is mechanical.** feature-001 AC-10 requires
`_dim_of_filename` to resolve `backlog.md` to `C7` in both twins
(`kb-actback-task.sh:193-234` and the twin map in `kb-dual-intent-probes.sh`, whose `D`
arm sits at `:249`). Once it does,
`_dim_owns_class(C7, Gotchas)` returns true (`kb-actback-task.sh:172`) and the
operational-structure presence check emits `| backlog.md | Gotchas | absent |` on every
run until the section exists — the check reports for *expected* classes whether or not
the doc is on disk (`:488-495`). The section's content is the traps of working the
backlog itself, which is genuine C7 delta-value rather than filler: the id is inherited
on promotion and re-minting it breaks the move audit; `## Next Release` is drained at tag
time, so parking an item there is a commitment; and an item is moved, never copied.

Today the check is silent on both documents because `_dim_of_filename`'s catch-all returns
`""` for any filename it does not list (`kb-actback-task.sh:231-232`). It is
feature-001 AC-10 that makes this live, which is why the obligation is stated here with
its trigger rather than discovered during implementation.

**3c. The `## MVP` anchor — settled here.** feature-001 §3b assigns the anchor to this
feature (*"the structure of `roadmap.md` (including the `## MVP` anchor) … is defined by
`/aid-create-roadmap`"*); feature-002 §3c (*Mechanics*) supplies the region mechanics.
Both are bound as follows — **the Source column refers, it does not restate**, so the
mechanics have exactly one home:

| Question | Answer | Source |
|----------|--------|--------|
| Heading text | The literal `## MVP`, matched exactly | feature-002 §3c *Mechanics* |
| Extent | To the next heading of level 2 or shallower, or EOF; `###` entries belong to it | feature-002 §3c *Mechanics* |
| Position when created | **Immediately after the `## Contents` block and before `## Now`** | **This section** |
| Who may create the section | `/aid-create-mvp` and `/aid-update-mvp` only | feature-002 §3c *Mechanics* |
| Who may create the document | `/aid-create-roadmap` only | feature-002 §3c *Mechanics*; REQUIREMENTS CC-5 |

**The position clause and feature-002 agree on disk — no amendment is owed.** An earlier
draft of this spec billed feature-002 for a correction, quoting §3c as reading
*"immediately after the document preamble, before the first other `##`"*. That is not what
feature-002 says: its *Position when created* row explicitly **rejects** that phrasing —
*"Immediately after the `## Contents` block, before the first content section — **not**
'before the first other `##`', which would place the MVP above the document index and
break KB layout order. feature-003 §3c owns the exact anchor and this row defers to it"*.
So feature-002 already defers to this row and already carries the layout-order reason.
What this section adds is only the concrete neighbour the deferral asks for: for
`roadmap.md` the first content section is `## Now`, so the anchor sits between
`## Contents` and `## Now`. The two specs are consistent as they stand, and §9 lists no
hand-back for it.

**`## Contents` lists `MVP` from the moment the document exists**, written by
`/aid-create-roadmap` as part of the preamble it owns, even while the section is still
absent. The alternative — having `/aid-*-mvp` co-edit the index — would make REQUIREMENTS
AC-6a's "writes only that section" false as stated. A forward index entry is the cheaper
of the two costs, and it is checkable (§8 V10).

*The cost, named, because a sibling feature makes the opposite state an oracle.*
feature-004 AC-11 (oracle V20) requires, over **its** four destinations, that the heading
set minus `## Contents` equal the `## Contents` entry set in both directions after every
`create`/`update`. Between `/aid-create-roadmap` and `/aid-create-mvp`, `roadmap.md`
violates exactly that equality in one direction — an entry with no heading — and V10
asserts that state deliberately. Three things bound the divergence rather than excusing
it: the invariant that exists on disk is `AS02`, which is **template-scoped** (it iterates
a `find` over `canonical/aid/templates/knowledge-base/`,
`test-kb-template-authoring-standard.sh:42,50`) and checks only that a `## Contents`
section is *present* (`:73-78`), so it neither sees `roadmap.md` nor asserts the equality;
feature-004's criterion is written over its own destinations and this spec claims no
exemption from it for those; and the divergent state is **transient by construction** —
it ends the first time `/aid-create-mvp` runs, and `/aid-*-roadmap` is forbidden from
creating the section (§4) precisely so the window closes only by the owner's hand. The
residual defect a reader can observe is a dead in-document anchor (`#mvp` resolving to
nothing) during that window; it is accepted, and it is the reason AC-6a is literally true.

**MVP section shape** — it is a decision entry like any other, so it carries the same
fields:

    ## MVP

    - **What:** the first shippable slice, itemized.
    - **Why:** why the line falls there.
    - **Rejected:** what was cut from the slice, each with the reason for the cut.
    - **Status:** Not started | In progress | Shipped <version> -- with the evidence
      anchor.

**3d. What neither document carries.** REQUIREMENTS C-3 binds both, and with no template
in existence the obligation lands on the authoring skill:

- No `## Change Log` and no `## Revision History` section; no `changelog:` frontmatter
  field; no work id and no work-folder path.
- `AS03`/`AS03b`/`AS03c` **cannot** discharge this. Those assertions iterate a `find` over
  `canonical/aid/templates/knowledge-base/` (`test-kb-template-authoring-standard.sh:42,50`)
  and can never see a document that has no template there — feature-001 AC-5 reaches the
  same conclusion. The oracle is a direct grep over the two instances (§8 V12).
- No `intent:` and no `contracts:`. `intent:` is superseded by `objective:`/`summary:`
  (`frontmatter-schema.md` § `intent:`), and `contracts:` is optional with an explicit
  "when in doubt, omit".
- No `## Gotchas` in `roadmap.md`: D owns none of the four operational-guidance classes
  (`concern-model.md:342`), so the presence check neither expects nor reports it.

### 4. Region ownership in `roadmap.md`

The mechanics are specified once in feature-002 §3c and are not restated here; §3c is
where the region's identity, extent and write discipline live. This section states only
how the nine skills apply them, plus the concrete anchor neighbour §3c defers to this
feature (§3c above).

**What is bound, precisely, and why the two specs now agree.** feature-002 §3c has three
parts and this feature binds all three: *Scope* (the rule binds the 36 new skills only),
*The first-write rule* (the table this section's routing rows implement), and *Mechanics*
(the region's identity, extent, position and write discipline). An earlier draft of this
spec bound §3c wholesale while §3c's first-write rule contained a clause that flatly
contradicted the routing below — a single row reading *"Destination document absent →
`create` creates the document … applies to `/aid-create-roadmap` and `/aid-create-mvp`
alike"*. **That row has since been split**, and feature-002's first-write table now
distinguishes the two cases: a skill that *"owns the whole document"* creates it, while a
skill that *"owns only a region"* — *"The only instance is `/aid-create-mvp` →
`/aid-create-roadmap`"* — routes, names the owner, and leaves the seed in place. That is
the same rule REQUIREMENTS FR-1 and CC-5 state, and it is what the `roadmap.md`-absent
rows below and AC-1 assert. The contradiction is retired on both sides; §9 carries no
hand-back for it.

**Read–modify–write, never regenerate.** A skill writing `roadmap.md` reads the whole
file, replaces only its owned byte range, and writes back with the other region
byte-identical.

| Situation | Behavior |
|-----------|----------|
| `roadmap.md` present, `## MVP` absent, `/aid-create-mvp` or `/aid-update-mvp` runs | Creates it between `## Contents` and `## Now` |
| `## MVP` absent, `/aid-*-roadmap` runs | Leaves it absent — never creates it; the `## Contents` entry for it stays |
| `## MVP` present, `/aid-*-roadmap` runs | Preserves it byte-identically |
| `## MVP` present with content, `/aid-create-mvp` runs | Routes to `/aid-update-mvp` (§6b); the seed survives for that run |
| `roadmap.md` absent, `/aid-create-mvp` runs | Routes to `/aid-create-roadmap`; creates nothing; the seed survives |
| `roadmap.md` absent, `/aid-create-roadmap` runs | Creates the document (§6b) |
| `roadmap.md` absent, `/aid-update-roadmap` or `/aid-update-mvp` runs | Routes to `/aid-create-roadmap`; writes nothing |

**Verification is byte-comparison, not inspection**, and it binds both mvp verbs.
REQUIREMENTS AC-6a says "`/aid-*-mvp` writes only that section" — `update` is a writer
too, and the table above grants it the power to create the region, so an oracle that exercises
only `create` leaves the more dangerous writer untested (§8 V7, V8).

### 5. Item flow — three stages, and `roadmap.md` is not one of them

REQUIREMENTS §5.1 fixes the flow, and these skills are what move an item along it:

```
tech-debt.md  ──promote──▶  backlog.md  ──ship──▶  release-tracking.md
 (observed,                 (accepted into        (shipped; purely
  unscheduled)               the plan)             historical)
```

`roadmap.md` sits **beside** this flow, not inside it. It holds direction at a coarser
granularity than items: a roadmap entry says where the project is going and why, and no
item id ever appears in it (§3a). REQUIREMENTS §5.1 states the correction and its reason
under the heading *"`roadmap.md` is not a stage in that flow"* — placing `roadmap.md`
between `backlog.md` and `release-tracking.md` would make a committed item live in two
documents at once, contradicting the move-not-copy rule in the same paragraph.
feature-001's Description carries the same three-stage diagram.

| Transition | Owner | Trigger | Key matched |
|------------|-------|---------|-------------|
| `tech-debt.md` → `backlog.md` | `/aid-design-backlog` proposes; `/aid-create-backlog` or `/aid-update-backlog` writes | The item is **accepted into the plan** — an explicit human decision at a confirm gate | The `ID` column of `tech-debt.md`'s inventory table (`:73`) |
| `backlog.md` → `release-tracking.md` | `release-aid` (feature-001 §4b, AC-7) | Tag time | The `Title` of each `## Next Release` row |

There is no third transition. Nothing moves into or out of `roadmap.md`, and
`/aid-*-roadmap` removes nothing from `backlog.md`.

**The promotion criterion is a decision, not a derivable property.** REQUIREMENTS
§5.1's "acquires a definition and a priority" is necessary but not sufficient: every row
in the live inventory already carries both, so a skill applying that rule literally would
promote the whole of `tech-debt.md` on its first run. feature-001 §3c settles it — the
item moves when someone **accepts it into the plan**, and the acceptance is the event.
The mechanism is this feature's: `/aid-design-backlog` proposes candidate rows in the
seed, and the `create`/`update` skill presents them for explicit per-item confirmation
before any row moves. Nothing is promoted without that confirmation.

**Move, not copy.** Each transition removes the item from the source document in the same
run that adds it to the destination. Because the id is carried unchanged (§3b), an item
present in both `tech-debt.md` and `backlog.md` is a checkable defect, not a judgment call
(§8 V18).

**Column mapping for a promotion**, so the move is a move and not a re-authoring:

| `tech-debt.md` column | `backlog.md` column |
|-----------------------|---------------------|
| `ID` | `ID` (unchanged) |
| `Description` | `Definition & done-condition` |
| `Location` | `Location` |
| `Risk` | `Risk if not done` |
| `Priority` | `Priority` |
| `Type` | **consumed, not carried** — read to seed `Tag`'s default, then dropped as a column (§3b) |
| `Effort` | dropped (§3b) |
| — | `Tag`, seeded from `Type` by §3b's rule and confirmed at the same gate that authorizes the move |

**Column mapping for a release-note bullet** — the second and last arm, settled by work
`STATE.md` Q7 (Resolved: shape (a), *derive-from-shipped*). The one-off migration that
retires `release-tracking.md`'s `## Unreleased` section moves its items into
`## Next Release` (feature-001 §4a; REQUIREMENTS AC-4). Such an item is **already built and
merely unreleased**, so its source is a tagged release-note bullet rather than an inventory
row, and the bullet supplies only two of the seven columns directly. This arm derives the
rest, so the migration composes no field from nothing.

**There is no exemption: a migrated row carries all seven columns like every other row.**
Q7 rejected the alternative — exempting migrated rows — because an exemption forks the row
schema permanently and obliges every later consumer (the release drain, V18's duplicate-item
oracle, the C7 depth standard) to handle two shapes.

| Source | `backlog.md` column |
|--------|---------------------|
| — | `ID`, minted in whatever form the project's own `tech-debt.md` inventory already uses, taking the next unused ordinal (§3b, *born in the backlog*); never reuses a retired id |
| The bullet's `[NEW]` / `[CHANGE]` / `[FIX]` marker | `Tag`, carried verbatim — the drain re-tags nothing (§3b) |
| The bullet's leading feature name, or its first clause | `Title` |
| The bullet's own text | `Definition & done-condition`, with the done-condition read as **shipped, pending tag** |
| The durable anchor the bullet already names | `Location` — path plus a grep-recoverable symbol or heading, never `path:LINE` |
| — | `Risk if not done`: **ships untagged / absent from the next release notes** |
| — | `Priority`: **`P1`** — the `## Next Release` slice is the committed slice by definition |

**The one cross-document write, justified precisely.** `/aid-create-backlog` and
`/aid-update-backlog` delete promoted rows from `tech-debt.md` — a second document,
outside their nominal destination. Two facts make that legitimate, and the first
correction matters because an earlier draft got it wrong: `tech-debt.md` **does** have a
declared owner — `tech-debt.md|aid-researcher-quality|required` at `.aid/settings.yml:54`,
mirrored in the ownership map at `doc-set-resolve.md:90` — but that owner is the
freshness-accountable **researcher slot**, not a `create`/`update` skill, and no skill in
this work claims a region in the file. And feature-002 §3c scopes one-owner-per-region to
**the 36 new skills only**; it is not a claim about the destination documents in general.
The write itself is a whole-row deletion keyed on the `ID` column, never a rewrite of any
other row and never a change to the file's prose.

**The retired four-stage model was hunted as a class, not corrected as a line.** The
previous draft carried it in four places — the section heading, the diagram, the
transition table, and the duplicate-item oracle — and each was rebuilt rather than
patched. The check that it stayed retired is a search, stated so it can be re-run rather
than trusted: **`grep -n 'release-tracking' <this file>`**, every hit read against one
invariant — *no hit may place `release-tracking.md` downstream of `roadmap.md`, and no
hit may give `roadmap.md` a transition row*. Every hit satisfies it, and each falls into
one of six kinds:

1. the three-stage flow itself — the diagram, the transition table, AC-8, and the prose
   stating why `roadmap.md` is not a stage in it;
2. the drain's oracle (V19), whose source document is `backlog.md`;
3. the two new documents' `summary:` and `see_also:` frontmatter, which name it as a
   sibling holding shipped work;
4. the `Tag` column rule and its derivation (§3b), which cite its body rule as the owner
   of the tag vocabulary;
5. the `kb-category` tally in §3a, which counts it as one of the three `extension` docs;
6. this paragraph.

The runtime counterpart to the textual check is §8 V20: no item id reaches `roadmap.md`
at all, whatever this document says.

### 6. Per-skill behavior

Each skill follows feature-002 §3e's on-demand shape: Work Initiation Gate →
`worktree-lifecycle.sh create` on new work → allocate `pipeline.path: lite`,
`initiator: aid-<verb>-<artifact>`, **`phase` not driven** → dispatch `aid-architect`
tiered → full verify → present → done. All three artifacts are **class 1**
(feature-002 §3b), so the readiness gate, seed consumption, and full verify all bind.

**6a. `design` (three skills).** Reads its own seed if present, plus `.aid/knowledge/` and
the project source; writes only `.aid/design/<artifact>.md` per feature-002 §4's template.
Re-invoking iterates the same seed — *Current direction* is rewritten, *Options
considered* accumulates. Terminates by presenting; never writes the KB.

*A recorded deviation from FR-1.* FR-1's table gives the `design` verb a `Reads` value of
`.aid/design/` alone. feature-002 §3a widens it to "its seed if present, KB, project
source", and this feature follows feature-002. The widening is deliberate — a roadmap seed
written without reading the KB would restate what the project already documents — but it
is a departure from the requirement's own table and is recorded rather than absorbed.

| Skill | Draws out |
|-------|-----------|
| `aid-design-roadmap` | Direction and its *why*; what is committed vs. merely wanted; sequencing rationale; the alternatives being rejected and why |
| `aid-design-mvp` | The line: what is in the first shippable slice, what defers, and the reason for each cut |
| `aid-design-backlog` | Item definitions, done-conditions and priorities; which `tech-debt.md` rows the user is accepting into the plan (§5) |

**6b. `create` (three skills).** The full class-1 contract applies: refuse while the
seed's `## Open questions` is non-empty unless overridden (feature-002 §4's detection
rule), realize the seed into the owned region, offer any additional user-requested output,
then **delete the seed**.

*The destination rule is stated at the region level*, per REQUIREMENTS FR-1's
populated-destination clause: the destination document existing or carrying content never
blocks `create`; `create` routes to its `update` counterpart only when **its own owned
region** already carries committed content, and it never halts with nothing offered.

| Skill | Document absent | Document present, owned region empty/absent | Owned region already populated |
|-------|-----------------|---------------------------------------------|--------------------------------|
| `/aid-create-roadmap` | **Creates** `roadmap.md` — frontmatter, title, preamble, `## Contents` (incl. the `MVP` entry), and the three horizon sections | Fills the horizon sections | Routes to `/aid-update-roadmap` |
| `/aid-create-mvp` | Routes to `/aid-create-roadmap` — an MVP is a section of a roadmap, not a document (REQUIREMENTS CC-5; feature-002 §3c *first-write rule*) | Creates `## MVP` at the anchor position (§3c) | Routes to `/aid-update-mvp` |
| `/aid-create-backlog` | **Creates** `backlog.md` — frontmatter, title, preamble, `## Contents`, `## Next Release`, `## Prioritized`, `## Gotchas` | Fills the item tables | Routes to `/aid-update-backlog` |

**A routed seed still gets consumed — settled at REQUIREMENTS CC-3.** When `create`
routes, it has realized nothing, so the seed must survive, and the `update` run it routes
to is then the realization event. CC-3 amends FR-1's table for the whole work: `update`
reads the KB document *and its `.aid/design/` seed when one is present, consuming it as
`create` would*, while never *requiring* one. The three `update` skills in this feature
apply that rule to their own region and to no other. This spec states no local variant of
it, and §9 carries no hand-back for it: the rule has one home and it is FR-11.

**Registration on creation.** When a `create` skill creates its document it also registers
it in the project's `.aid/settings.yml` under the physical key `knowledge.doc_set` — the
same block `doc-set-resolve.md` documents under its logical name `discovery.doc_set` — so
that `resolve_doc_set`, and therefore `/aid-discover`, `/aid-housekeep` and the review
gates, see it from that point on. This binds `/aid-create-roadmap` and
`/aid-create-backlog` only; `/aid-create-mvp` creates no document (CC-5) and so writes
neither surface.

**The presence value is `required`, per REQUIREMENTS CC-1** — the settled rule for every
conditional document this work admits, referred to here rather than re-argued. The two
values answer different questions: the per-domain matrix row stays `conditional:<when>`
(feature-001 §1c owns it), and the *resolved* doc-set entry the skill writes says the
document is expected for **this** project, which it is the moment the skill creates it.

| Surface | Entry written | Form fixed by |
|---------|---------------|---------------|
| `.aid/settings.yml` `knowledge.doc_set` | `roadmap.md\|skill-self\|required` / `backlog.md\|skill-self\|required` | REQUIREMENTS CC-1 for the presence value; `doc-set-resolve.md:28-41` § Field grammar for the shape (field 2 must be a researcher slot or `skill-self`; field 3 is `required \| conditional[:<when>]`) |
| `.aid/knowledge/README.md` | One Completeness row — `Concern` = the doc's spine dimension (`D` for `roadmap.md`, `C7` for `backlog.md`), `Owner` = `skill-self`, `Status` = the literal `Created (skill-self)` — and the `**Doc-set:** N documents` line at `:21` incremented | The table's own rule at `README.md:35` — one row per doc-set entry |

*Why the `Status` cell names a token the table does not use today.* The live column holds
two values, `Generated` and `Restored (hand-authored)` (`.aid/knowledge/README.md:38-59`),
and neither is true here: the table's own legend defines `Generated` as *"authored this
discovery run"* (`:35-36`) and no discovery run authored these. The column carries no
closed enum — its two live values differ in form, one bare and one parenthesized — so a
third value is admissible, and stating the literal is what makes V15 checkable instead of
turning on the author's choice of wording.

Two reconciliations this creates, both stated because a reviewer will otherwise read them
as conflicts:

1. `aid-config/SKILL.md:160` records `knowledge.doc_set` as *"runtime-written by
   `aid-discover`"*. These skills are a **second** runtime producer of the same key. They
   follow the same R13 append-block idiom the same line documents — appending one entry to
   the existing `doc_set:` list, never rewriting the block, never touching
   `term_exclusions` — and that line must be amended to name them. The amendment is one
   row and is shared with feature-004, whose `/aid-create-testing-strategy` writes into
   the same key by the same append-block mechanism (feature-004 §8a for `quality-gates.md`,
   §3b for its general creation path); whichever lands first writes it naming both. The
   *presence value* those entries carry is not a per-feature choice and is not restated
   here or there — REQUIREMENTS CC-1 fixes it at `required` for every conditional document
   this work admits.
2. **The registration is an effect of running the skill, and no other feature performs it
   — settled at REQUIREMENTS CC-2.** This repository's own `knowledge.doc_set` moving
   19 → 21, and `README.md`'s two counts with it, are the *result* of running these two
   `create` skills here; feature-001 sequences that step after this feature's creation
   (its §6 step 4→5) and does not hand-edit the entries itself. CC-2 is what makes that
   division binding rather than a reading, so this spec states it once and V15 is the
   oracle that exactly one added line appears per created document.

**6c. `update` (three skills).** Reads the destination and its artifact's seed if one
exists, edits only its owned region, deletes a consumed seed, and asks the user —
**every run, no exceptions and no stored list** (FR-8, feature-002 §3d) — which
previously created outputs to update alongside it. Writes no tracking metadata into
anything: no frontmatter backlink, no manifest, no registry, no state between runs.

| Skill | Owned region | Destination absent | Artifact-specific duty |
|-------|--------------|--------------------|------------------------|
| `/aid-update-roadmap` | `roadmap.md` minus `## MVP` | Routes to `/aid-create-roadmap`; writes nothing | Adds, revises and supersedes direction entries; moves an entry between horizon sections; never touches `## MVP`, and leaves the `MVP` index entry in place whether or not the section exists |
| `/aid-update-mvp` | `roadmap.md`'s `## MVP` only | Routes to `/aid-create-roadmap`; writes nothing | May create the region if the document exists without it (§4); revises the slice and its `Status`, including the transition to `Shipped <version>` |
| `/aid-update-backlog` | `backlog.md` | Routes to `/aid-create-backlog`; writes nothing | Re-prioritizes; adds items; promotes confirmed `tech-debt.md` rows and deletes them there in the same run (§5); keeps `## Next Release` in step with what is actually committed |

**6d. The `description` negative-routing obligation, discharged per skill.** feature-002
§3e states the contract once and leaves per-skill application to the consuming features;
NFR-4 and REQUIREMENTS AC-8 require it. This feature ships the most confusable pair in
the work — two skills writing the same file — so the neighbour is assigned explicitly
rather than left to the author:

| Skill | Nearest confusable neighbour named in `description` |
|-------|-----------------------------------------------------|
| `aid-design-roadmap` | `/aid-design-mvp` (the first slice) — and `/aid-create-roadmap`, which is what writes the KB |
| `aid-create-roadmap` | `/aid-create-mvp` (the `## MVP` section) and `/aid-update-roadmap` (a roadmap that already has entries) |
| `aid-update-roadmap` | `/aid-update-mvp` (the `## MVP` section) |
| `aid-design-mvp` | `/aid-design-roadmap` (direction beyond the first slice) — and `/aid-create-mvp` |
| `aid-create-mvp` | `/aid-create-roadmap` (creates the document itself) and `/aid-update-mvp` |
| `aid-update-mvp` | `/aid-update-roadmap` (everything outside `## MVP`) |
| `aid-design-backlog` | `/aid-design-roadmap` (direction, not items) — and `/aid-create-backlog` |
| `aid-create-backlog` | `/aid-update-backlog` (a backlog that already has items) |
| `aid-update-backlog` | `/aid-create-backlog` (no backlog yet) |

Each `design` row names two routes because it has two confusions to resolve — the wrong
artifact and the wrong stage.

**Ownership of these nine assignments is not in question, per REQUIREMENTS CC-9:** every
neighbour named above is itself one of this feature's nine skills, so both sides of every
pair are new and both are shipped here. No pair in this table crosses a feature boundary,
which is why V25 can check all nine sides at this feature's own close rather than
deferring to feature-006's whole-set sweep (§9).

### 7. Interaction with the pipeline

These skills **do not** feed the numbered pipeline automatically. A roadmap entry does not
become a work and a backlog item does not become a work; a human runs `/aid-describe` or a
shortcut when they choose to.

**Attributed accurately, unlike the previous draft, which sourced the prohibition to two
requirements that do not contain it.** No requirement forbids such a bridge: FR-3 says the
skills are invoked on demand and the closed `phase:` enum is not extended, and NFR-3 says
no new phase, no new enum value, no change to the work/delivery/task hierarchy. An
automatic backlog-item-to-work bridge violates neither text as written. It is out of scope
for a simpler reason — no requirement asks for one, §5.3's skill set contains no such
skill — and the only mechanisms that could carry it are the ones C-1 and NFR-3 close off.
That is the honest form of the warning, and the warning is still worth making: "backlog →
work" reads like an invitation to build it.

### 8. Verification

Every row names a command, a test id, or a diff that fails if the work is done wrong.

| # | Check | Oracle |
|---|-------|--------|
| V1 | Nine directories, nine rows | `ls -d canonical/skills/aid-{design,create,update}-{roadmap,mvp,backlog}` → 9; `grep -cE '^  - name: aid-(design\|create\|update)-(roadmap\|mvp\|backlog)$' canonical/aid/templates/shortcut-catalog.yml` → 9 |
| V2 | Hand-authored, not generated | Run `build-shortcut-skills.py`, then `git diff --exit-code canonical/skills/aid-*-{roadmap,mvp,backlog}/` — a row that lost `repurpose: true` makes the helper emit a doorway and the diff non-empty. This is the key's **only** job (§1); the bodies' non-use of the engine is a separate property, asserted by `grep -rLn 'shortcut-engine' canonical/skills/aid-*-{roadmap,mvp,backlog}/SKILL.md` listing all nine |
| V3 | Row fields complete | For each of the nine rows, all eight fields present with `default_type` in the closed 8-enum and `group` ∈ {G3,G4,G5}: `awk` over the row block asserting 8 keys; `test-catalog-dirs-parity.sh` green |
| V4 | `design` never touches the KB | Run each of the three `design` skills; `git status --porcelain .aid/knowledge/` empty |
| V5 | Seed consumed at `create` | Seed present before, absent after — for `mvp`, **with `roadmap.md` pre-existing**; run standalone against an absent roadmap the run routes instead (V16) |
| V6 | Readiness gate | `create` against a seed whose `## Open questions` is non-empty by feature-002 §4's detection rule refuses without an override; the destination is byte-identical afterwards and the seed still present; and the run's transcript names the unresolved question(s) **and** the override, per AC-10. A refusal that names neither fails this row even though it wrote nothing |
| V7 | **REQUIREMENTS AC-6a — `## MVP` preserved** | Capture the `## MVP` byte range → run `/aid-create-roadmap` **and** `/aid-update-roadmap` → bytes identical |
| V8 | **REQUIREMENTS AC-6a — mvp writes only its section** | Run `/aid-create-mvp` **and** `/aid-update-mvp`; `git diff -U0 .aid/knowledge/roadmap.md` touches only lines inside the `## MVP` range |
| V9 | Anchor position and heading order | Fresh `/aid-create-roadmap` → `grep -n '^## ' roadmap.md` = Contents, Now, Next, Later, **in that order**, and the four `## Contents` entries are the house link form of exactly those four section names plus `MVP` (§3a). Then `/aid-create-mvp` → Contents, MVP, Now, Next, Later, and `git diff --numstat` shows **0 deletions** (a pure insertion). The same heading-order assertion over `backlog.md`'s four sections is V15's |
| V10 | Index carries the forward entry, in the fixed form | After `/aid-create-roadmap` alone, `grep -c '^- \[MVP\](#mvp)$' .aid/knowledge/roadmap.md` → 1, with no `## MVP` heading present. Anchored on §3a's literal entry form, so a bare `- MVP` list fails rather than passing vacuously |
| V11 | Frontmatter shape | `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge --verbose` → exit 0, no `[FM-MISSING]`/`[FM-INVALID]` naming either document, **and** neither document on a `SKIP` line. The second half is what keeps the row non-vacuous: the linter soft-skips any doc carrying none of the new fields (`lint-frontmatter.sh:344-354`), so a document authored without §3a's field set would pass by being invisible |
| V12 | **C-3 compliance** | `grep -nE '^## (Change Log\|Revision History)\|^changelog:\|work-[0-9]{3}\|\.aid/works/' .aid/knowledge/roadmap.md .aid/knowledge/backlog.md` → no match. Not AS03/AS03b/AS03c, which are template-scoped (§3d) |
| V13 | Durable citations | `bash canonical/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` → exit 0 (catches a `Location` cell written as `path:LINE`) |
| V14 | C7 ownership satisfied | `bash canonical/aid/scripts/kb/kb-actback-task.sh check --doc-set <resolved TSV> --kb-dir .aid/knowledge` emits `\| backlog.md \| Gotchas \| present \|` and no `absent` row for either document |
| V15 | Creation on demand + registration — **both documents** | Run twice, once per document. Absent `roadmap.md` → `/aid-create-roadmap` → the file exists and carries §3a's four `create`-time headings (`## Contents`, `## Now`, `## Next`, `## Later` — `## MVP` is `/aid-create-mvp`'s, §4); `git diff .aid/settings.yml` shows exactly one added line, byte-equal to `    - roadmap.md\|skill-self\|required`; `README.md`'s Completeness table gains exactly one row, whose `Status` cell is the literal `Created (skill-self)`, and its `:21` count increments by 1. Then absent `backlog.md` → `/aid-create-backlog` → the file exists and carries §3b's four headings (`## Contents`, `## Next Release`, `## Prioritized`, `## Gotchas`), with the same three assertions over `backlog.md\|skill-self\|required`. A run that creates the document but skips either surface fails; so does one that writes `conditional` (CC-1) |
| V16 | `/aid-create-mvp` without a roadmap | Routes to `/aid-create-roadmap`, naming it; `roadmap.md` still absent; `.aid/design/mvp.md` still present |
| V17 | `update` with an absent destination | For each of the three `update` skills: routes to **the absent document's owner** — `/aid-create-roadmap` for both `/aid-update-roadmap` and `/aid-update-mvp` (a region-owning skill routes to the document's owner, not to its own `create` counterpart — §4, CC-5), `/aid-create-backlog` for `/aid-update-backlog` — and `git status --porcelain .aid/knowledge/` is empty. The transcript naming `/aid-create-mvp` for the mvp case is the failure this row exists to catch |
| V18 | **No item in two documents** | `comm -12 <(ids tech-debt.md) <(ids backlog.md)` → empty, where `ids` extracts column 1 of the inventory tables. Non-vacuous because the id is carried unchanged on promotion (§3b) |
| V19 | Drain lands where it should | After `release-aid`, each `## Next Release` title is absent from `backlog.md` and present as a tagged bullet in the new `release-tracking.md` version section (feature-001 AC-7). `grep -c 'roadmap.md' .claude/skills/release-aid/SKILL.md` → 0 |
| V20 | No item id in `roadmap.md` | For every id in `tech-debt.md` ∪ `backlog.md`, `grep -Fc "<id>" .aid/knowledge/roadmap.md` → 0 |
| V21 | **FR-8 — asked every run** | Run an `update` skill twice in one project: run 2's transcript contains the derived-outputs question; `git status --porcelain` after run 1 shows no new file beyond the destination and the outputs the user named; `grep -rnE 'derived\|outputs' .aid/settings.yml` finds no stored list |
| V22 | **REQUIREMENTS AC-7 — no tracking metadata** | Each generated non-KB output carries no frontmatter backlink field and no skill-attribution line: `grep -nE 'aid-(create\|update)-(roadmap\|mvp\|backlog)\|source_doc:\|generated_by:' <output>` → no match |
| V23 | `phase` not driven | After each of the nine skills runs, its work's `STATE.md` has no `phase:` value: `grep -n '^phase:' .aid/works/<work>/STATE.md` → absent or empty. (Replaces a diff on `work-state-template.md`, which this feature never touches and which therefore could not fail) |
| V24 | Absent is clean — the skill-side half | On a project that has run only `design` and `update` skills: no `roadmap.md`, no `backlog.md`, no `knowledge.doc_set` entry for either. The gate-side assertion is feature-001 AC-4's, against a fixture KB; this row asserts only that `create` is the sole producer |
| V25 | **REQUIREMENTS AC-8 — negative routing present** | For each of the nine `SKILL.md` files, the frontmatter `description` contains the literal name of every neighbour §6d assigns it — 9 of 9 by grep. A description that names no neighbour, or names one §6d does not assign, fails |
| V26 | Render parity and counts | Full `run_generator.py` + byte-identity gate (feature-006 §6 *Render and dogfood*, steps 1–4), and the count-bearing-surface sweep run through `check-skill-counts.mjs` plus the four hardcoded catalog assertions (feature-006 §3 and §4). Both are feature-006's to run; this row is the hand-off, not a second execution |
| V27 | `update` produces a revision | For each artifact, after its `create` has run: change one thing via the `update` skill; `git diff .aid/knowledge/<destination>` is **non-empty**, every hunk falls inside that skill's owned region (§6c), and the artifact's seed — if one was present — is gone afterwards (CC-3). This is AC-1's third step, which no other row asserts |
| V28 | The catalog's own count comments are not left stale | Three comment counts inside `shortcut-catalog.yml` state row populations and are invalidated by the nine rows: the G4 header's *"16 canonical rows (12 in this section…)"* (`:145-147`), the G5 header's `15 canonical aid-update* rows (12 in this section...)` (`:233-236`), and the schema's *"24 rows carry `repurpose: true`"* (`:108-109`). None is covered by `check-skill-counts.mjs`, although it scans `canonical/` and admits `.yml`: verified by running `node tests/canonical/check-skill-counts.mjs --list`, which prints every claim it checks and every marker-exempted line — **no line of `shortcut-catalog.yml` appears in its output** (175 claims checked, guard green). Its `CLAIMS` patterns (`:63-118`) key on phrasings like *"N canonical names"* and *"N `repurpose` rows"*, none of which these three comments use. So the guard stays green over all three while they are false. Oracle, runnable at close-out: `grep -c '^  - name: aid-create' `, `grep -c '^  - name: aid-update' ` and `grep -c '^    repurpose: true$' ` over the catalog each equal the number its comment states. Today 16 / 15 / 24; after all 36 new rows land (nine here, twelve in feature-004, fifteen in feature-005), 23 / 22 / 60 |

**Which rows would catch a real regression.** V7, V8, V9, V14, V18 and V27 compare bytes,
positions, set intersections or diff extents, and V15 compares exact strings against two
surfaces. The rest are presence assertions, and are labelled as such rather than presented
as equals.

**Coverage, both directions.** Every criterion has an oracle and every one of the 28 rows
serves a criterion. The criteria are this spec's own AC-1..AC-12, not REQUIREMENTS' —
where a row's title names a REQUIREMENTS id it says so.

| Criterion | Rows | Criterion | Rows |
|-----------|------|-----------|------|
| AC-1 | V5, V15, V16, V27 | AC-7 | V15, V24 |
| AC-2 | V7 | AC-8 | V18, V19, V20 |
| AC-3 | V8 | AC-9 | V1, V2, V3, V26, V28 |
| AC-4 | V21, V22 | AC-10 | V6, V16, V17 |
| AC-5 | V4 | AC-11 | V23 |
| AC-6 | V9, V10, V11, V12, V13, V14, V15 | AC-12 | V25 |

Two rows serve more than one criterion, and both are accounted for rather than left as an
apparent length mismatch. **V15** serves three: it is the sequence's middle step (AC-1),
the registration criterion (AC-7), and — because it is the only row that runs
`/aid-create-backlog` on an absent destination — the shape check for `backlog.md`'s
headings (AC-6). **V16** serves two: the standalone mvp case is both a sequence case
(AC-1) and a routing case (AC-10).

### 9. Dependencies, hand-offs, and sequencing

**Citation discipline for this section, and for every cross-spec claim above.** The five
sibling specs are under review in parallel, so every reference to one of them names a
**section anchor** (`feature-002 §3c *Mechanics*`), never a line range. A line range in a
sibling spec is stale by the next revision, and two of the previous draft's HIGH findings
were exactly that failure: a quotation attributed to lines that had come to hold something
else. Where a shared rule is settled work-wide, the reference is to REQUIREMENTS FR-11's
`CC-n`, and the rule is **referred to, never restated** — restating it in six specs is the
drift FR-11 exists to end.

- **Depends on feature-001** — for **membership and doctrine only**: the conditional
  matrix rows, the `concern-model.md` entries, the `document-expectations.md` blocks, the
  `_dim_of_filename` entries, and the two doctrine amendments that make the documents
  admissible at all (feature-001 §1b, §2; the set is fixed work-wide by REQUIREMENTS
  CC-4). **There is no template to depend on** (feature-001 §1a, AC-2;
  `find canonical/aid/templates -type f \( -iname '*roadmap*' -o -iname '*backlog*' \)` →
  nothing — scoped to the template tree, since an unscoped `find canonical …` matches the
  six skill directories this feature creates). This feature owns
  shape and creation, including this repository's instances (feature-001 §3b).
- **Depends on feature-002** — binds **§3a** (both stage tables), **§3c** in all three
  parts (scope, the first-write rule, the mechanics), **§3d**, **§3e**, **§3f**, **§3g**
  and **§4**: exactly the set feature-002 §6's interface table assigns this feature, no
  more and no less. It additionally *reads* **§3b** for the class-1 designation §3g's
  binding table keys on (§6 below asserts all three artifacts are class 1); §3b is a
  classification this feature consumes, not a contract it binds, which is why
  feature-002's interface row omits it and this bullet lists it separately rather than
  quietly widening the set.
- **Depends on feature-001 §4b for the drain's source.** `release-aid` drains committed
  items from **`backlog.md`**, not `roadmap.md` — feature-001 §4b and AC-7 both say so,
  and `grep -rn 'roadmap.md' .claude/skills/release-aid/SKILL.md canonical/` returns
  nothing today. §5 matches it.
- **No contract amendments are owed to feature-002.** The previous draft billed it for
  two, and both are now closed on disk rather than outstanding: (i) the `## MVP` position —
  feature-002 §3c's *Position when created* row already rejects the phrasing that draft
  attributed to it and already defers the exact anchor to this feature's §3c; (ii) the
  routed seed's consumer — settled work-wide by REQUIREMENTS **CC-3**, which amends FR-1's
  `update` `Reads` column for every feature at once, so neither spec carries a local
  variant. A third claimed drift is also retired: that draft quoted feature-002 §8 as
  reading *"whose structure and `## MVP` position feature-001's template defines"*. No such
  sentence exists in feature-002 (`grep -n 'whose structure'` over its SPEC returns
  nothing); §8's actual text is *"**Depends on feature-001: no.** … feature-001 has no
  template and says so"*, which agrees with this spec. Nothing is handed back.
- **Hands to feature-001 — the `document-expectations.md` block text.** feature-001 AC-11
  owns the surface; the *content* of the `### roadmap.md` and `### backlog.md` blocks is
  shape and comes from §3a/§3b — the field list, the entry schema, and the C7/D floors
  each document must meet.
- **Hands to feature-006 — nine catalog rows, nine directories, and three stale count
  comments.** The rows and directories feed the render (feature-006 §6) and the
  count-bearing-surface sweep (feature-006 §3–§4). The three comments are the ones V28
  names — the G4 and G5 family headers and the `repurpose` schema note inside
  `shortcut-catalog.yml` itself — and they are handed over rather than edited here because
  all three are shared with features 004 and 005: each of the three features invalidates
  the same numbers, so three independent edits would collide on one file. They are called
  out explicitly because feature-006's sweep runs `check-skill-counts.mjs`, and that guard
  demonstrably does not see them (V28).
- **Parallel with features 004 and 005 in directories and destinations, serialized on one
  file.** All three append rows to the single
  `canonical/aid/templates/shortcut-catalog.yml`, and C-5 requires
  `build-shortcut-skills.py` plus a **full** `run_generator.py` after any catalog edit.
  The rows are append-only and disjoint, so the three features do not conflict textually,
  but the render is run **once**, in feature-006, not per feature.
- **One divergence from feature-004, deliberate and bounded:** `source: hand-authored`
  here versus `forward-authored` on the documents feature-004's `create` skills create
  (its §7a, oracle V19). §3a states the reason — these two destinations have no as-built
  counterpart for the Conformance Lane to compare against, and the D-concern precedent
  `decisions.md` is `hand-authored` — and shows the cost is nil because `sources: []`
  leaves the doc←code lane no anchor. Recorded here so it reads as a decision rather than
  an inconsistency between two specs written on the same day.
- **Internal order:** §3 (both documents' shape — nothing can be authored before it) →
  the three `design` skills (they define what each seed contains) → the three `create`
  skills (they consume the seed and author the shape) → the three `update` skills (they
  need a destination that exists).
