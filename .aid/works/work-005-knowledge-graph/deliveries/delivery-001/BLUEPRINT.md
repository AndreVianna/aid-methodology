# Delivery BLUEPRINT -- delivery-001: Research Foundation

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-001
> **Work:** work-005-knowledge-graph
> **Created:** 2026-07-28

---

## Objective

This delivery produces the two decisions that unblock every implementation feature in the work:
the closed relation vocabulary (FR-4–FR-6; REQUIREMENTS.md D-1) and the graph rendering approach
(FR-18; D-2; STATE.md Q2). The vocabulary is authored as
`canonical/aid/templates/graph/relation-vocabulary.yml` and blocks feature-003 (which cannot
validate inverse pairs without it) and feature-005 (which cannot type a row without it). The
rendering research blocks feature-008 outright and conditions feature-011's validator carve-outs
and feature-012's dependency-packaging work.

**Recorded deviation from `aid-plan`'s core principle.** `aid-plan` wants every deliverable to be
a functional MVP usable without the next one. **This deliverable is not standalone-functional and
this BLUEPRINT says so plainly rather than pretending otherwise** — it ships two decisions, not a
capability a user can invoke. It is sequenced first for two grounded reasons: REQUIREMENTS.md §10
asked for it ("Research — the relation vocabulary (FR-5) and the rendering approach (FR-18). Both
block implementation (D-1, D-2)"), and the vocabulary genuinely blocks features 003 and 005, which
are the spine of delivery-002. The compensating property §10 names still holds: because the two
research features are separate, a stall in the rendering research does not stop
`relationships.md` and the gap ledger from shipping — only feature-008 waits on it.

Both features are RESEARCH-typed and write no product code, per
`.claude/skills/aid-execute/references/task-type-rules.md` § RESEARCH. The one permanent artifact
this delivery creates is the vocabulary file; everything else is a report in the transient work
folder.

## Scope

**In scope:**

- **feature-001-relation-vocabulary-research** — the closed relation/inverse vocabulary. Harvests
  real relationship instances from this repository, clusters and names them, screens candidates,
  and authors the single canonical source at
  `canonical/aid/templates/graph/relation-vocabulary.yml`: a `pairs:` block sequence of
  seven-key entries (`relation`, `inverse`, `symmetry`, `category`, `endpoint_kinds`, `passes`,
  `definition`) plus a `categories:` set, with the field contract, worked examples and addition
  process in the header comment block. The research report itself lands in the work folder.
- **feature-002-graph-rendering-research** — the rendering-approach decision record: bench scale
  derived from this repository under FR-21/FR-22, the candidate comparison matrix, spikes of the
  survivors, the fifteen-part decision record, and the drafted `technology-stack.md` /
  `infrastructure.md` entries.

**Out of scope:** nothing is deferred from this work. Specifically excluded from *this delivery*:
implementing the loader (`rel_load_vocabulary` — feature-003, delivery-002), selecting and
enumerating the `coverage_bearing` subset (feature-006, delivery-003), the manifest and install
wiring for the new canonical file (feature-012, delivery-002), landing the drafted
`technology-stack.md` / `infrastructure.md` / `artifact-schemas.md` / `domain-glossary.md` entries
(feature-013, delivery-006), and implementing the recommended renderer (feature-008,
delivery-005). Spike harnesses are throwaway and are not committed.

## Gate Criteria

Derived from feature-001's and feature-002's completion criteria. Neither feature satisfies a
REQUIREMENTS.md §9 acceptance criterion directly — both ship decisions — so the two §9 criteria
named below are recorded as **enabled here, satisfied downstream**.

- [ ] `canonical/aid/templates/graph/relation-vocabulary.yml` exists and, when **loaded** (not
      read), satisfies all five properties of feature-001's inverse-pair contract: closure (every
      `inverse` is some entry's `relation`), totality (exactly one `inverse` per entry),
      involution (`inverse(inverse(relation)) == relation`), symmetric consistency (`symmetry:
      symmetric` iff `inverse == relation`, no third case), and category totality (every entry
      carries exactly one `category`, every `category` used appears in `categories:` with a
      one-line meaning).
- [ ] Every entry carries all seven keys in the fixed order, obeys the restricted-YAML parse
      contract (one key per physical line, flow-only lists, closed enums, entries sorted by
      `category` then `relation`), and contains **no install-relative path and no filename
      placeholder** — `.yml` is outside `render.py`'s `_TEXT_EXTENSIONS`, so the file is copied
      verbatim and nothing in it is rewritten or fixed up.
- [ ] Every relation type declares `passes` (a non-empty subset of `declared` / `derived` /
      `inferred`) and `endpoint_kinds` over the `kb:` / `int:` / `ext:` prefixes, so feature-005
      knows which types each of its two passes may emit and can apply both as fail-closed
      map-load-time gates.
- [ ] Three worked `relationships.md` rows in the eight-column §5.2 shape are demonstrated — one
      KB-to-KB, one KB-to-source, one KB-to-external — each using only vocabulary terms in both
      relation columns, with free-text nuance confined to `Observation`. The KB-to-external row
      uses the Q4 synthetic fixture's keys, because `.aid/knowledge/external-sources.md` has zero
      registered entries (A-6: the fixture is self-built and depends on no work folder).
- [ ] **AC-2 is decidable without human judgment** given the delivered vocabulary. *Enabled here;
      satisfied by feature-003's `V3`/`V4` validators in delivery-002.*
- [ ] The rendering recommendation names **exactly one** approach and states why each rejected
      alternative was rejected, covering at minimum the four renderer classes (minimal
      layout/zoom modules, a higher-level graph library, a WebGL-class renderer, hand-rolled)
      **and** the rejected packaging shapes, including CDN delivery and build-step output.
- [ ] The decision record carries all fifteen required parts, and in particular: the bench scale
      and how it was derived from this repository (plus an order-of-magnitude overshoot bench);
      payload and packaging cost; licence and attribution obligations **with the place in the
      artifact where attribution must appear**; an update story naming *who or what notices*
      upstream movement (`.github/dependabot.yml` declares only `github-actions` today, so
      "nothing notices" is the current baseline); the accessibility cost of the recommended
      renderer against the WCAG AA bar and what it implies for feature-009's effort; the
      scale-versus-accessibility tension resolved explicitly at this project's measured node
      count; and the implication for feature-008's size.
- [ ] The runtime prerequisites — network access, companion asset files, or a build output — are
      stated **explicitly, as prose a reader can act on**. *This is the sentence AC-6 will be
      checked against; AC-6 itself is satisfied by feature-007 in delivery-004.*
- [ ] The drafted `technology-stack.md` entry (and, if a build step is recommended, the drafted
      `infrastructure.md` implications) is ready to land — drafted, not landed. Landing is
      feature-013's, in delivery-006.
- [ ] Neither feature changed product code or wrote to the Knowledge Base, and no spike harness
      was committed — the RESEARCH task-type rule.
- [ ] All section-6 quality gates pass: the delivery gate's `grade.sh` run over
      `.aid/.temp/review-pending/` reaches this repository's resolved `minimum_grade` of **A+**
      (`review.minimum_grade` in `.aid/settings.yml`; this work's `minimum_grade: "A+"`), i.e.
      zero findings with Status `Pending` or `Recurred`.

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** delivery-002 (the vocabulary blocks features 003 and 005), delivery-005 (the
  rendering recommendation blocks feature-008), delivery-006 (transitively, and for the drafted
  KB entries it lands)

## Notes

- **The two research features are deliberately separate.** feature-002's Dependency position
  records the reason: it blocks only feature-008, so keeping it apart from feature-001 preserves
  §10's decoupling — if the rendering research stalls, `relationships.md` and the gap ledger
  still ship. Both are grouped into this delivery for sequencing convenience, not because they
  are coupled; a delayed feature-002 should not hold delivery-002.
- **The vocabulary file is permanent; the reports are transient.** `CLAUDE.md` § "Tracking
  discipline" forbids any permanent artifact from depending on a specific work folder's contents.
  The vocabulary is loaded at runtime by shipped scripts, so it lives under `canonical/`; the
  research reports are pipeline evidence and live in the work folder. Anything downstream that
  must survive the work has to be restated in a permanent home — feature-008 may not cite the
  rendering report as its source of truth at ship time.
- **Adding the canonical file requires the FULL generator.** Per `infrastructure.md` § "The
  Build: Multi-Profile Render", the file is added by running the full generator so all five
  profile copies and their `emission-manifest.jsonl` records move together — never by
  hand-editing a profile copy. Because `.yml` renders as verbatim bytes, a vocabulary edit
  produces exactly six identical files plus five `sha256` updates. The manifest wiring itself is
  feature-012's, in delivery-002.
- **Left open by design, and to whom:** widening `rel_load_vocabulary` to the seven-key entry
  contract (feature-003, delivery-002); where the `coverage_bearing` subset lives (feature-006,
  delivery-003); whether `validate-visuals.mjs` needs a parameterised T2 exclusion, which closes
  once feature-002 names the renderer (feature-011, delivery-002).
