# Delivery BLUEPRINT -- delivery-006: Ship Gate

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-006
> **Work:** work-005-knowledge-graph
> **Created:** 2026-07-28

---

## Objective

This delivery is the single place a reviewer can stand to ask "is this actually finished?". It
brings the test suites, the documentation surfaces, and the Knowledge Base entries — every one of
which describes something another delivery built, and can therefore only be written truthfully
once that delivery has landed. A skill that ships but cannot be found has not really shipped, and
two things can only be checked at the end: that the skill genuinely arrived in all five host
profile trees and the dogfood tree byte-for-byte, and that the whole canonical suite is still
green run the way the project requires.

It is a feature and not a checklist because the Knowledge Base records the failure it exists to
prevent. Tech-debt **L4** is the test-effectiveness gap, and its proof case is the `io_bounds.py`
incident, in which "five install manifests plus two installer-test lists all asserted each other"
and passed while every one of them was stale. Documentation surfaces that nothing derives and
nothing tests are exactly that failure mode, and treating them as an afterthought at the end of
another feature is how they got that way. L4's own invariant-anchoring remedy — every assertion
compares a derived artifact to the source of truth, never to a sibling copy that can drift in
lockstep — is written directly into this delivery's registration criterion.

This is also where **feature-010's FR-28 gate closes over both artifacts for the first time**.

## Scope

**In scope:**

- **feature-013-tests-and-docs** — the four discoverability surfaces, the toolkit diagrams and
  their maintenance reference, the automated coverage parity with `/aid-summarize`, the
  registration suite, the full local canonical-suite run, and the ship-time Knowledge Base
  updates.
- The ship-time landings other features drafted and deliberately deferred here: feature-001's
  `artifact-schemas.md` entry (and `domain-glossary.md`, only if the vocabulary research coined a
  Concept Spine term) and feature-002's drafted `technology-stack.md` / `infrastructure.md`
  entries, if a third-party approach or a build step was adopted.
- The first full run of feature-010's FR-28 rubric across the data checks **and** the view checks.

**Out of scope:** nothing is deferred from this work. Specifically excluded from *this delivery*:
building any of the mechanisms it documents or verifies — each feature brings the tests that
prove its own mechanism, and this delivery adds only the two things that cannot be asserted from
inside the feature that built them. Editing the generated site catalogue directly is also out of
scope: `site/src/content/docs/reference/skills.md` is produced by `site/scripts/gen-reference.mjs`
and `site/src/content/docs/concepts/methodology.md` by `site/scripts/sync-docs.mjs`; both follow
from source edits plus the sync commands, and the `SKILL_GROUPS` roster entry itself is
feature-012's, landed in delivery-002.

## Gate Criteria

feature-013 satisfies no REQUIREMENTS.md §9 acceptance criterion of its own — the §9 criteria all
close in deliveries 002 through 005. Its criteria are the two feature-011 carried before the
three-way split (discoverability and coverage) plus the ship gate itself.

- [ ] **Discoverability across all four surfaces.** The skill is listed in the reference
      documentation (`docs/repository-structure.md`, `docs/aid-methodology.md`'s skill-inventory
      tables and its G1 group box, `docs/glossary.md`, `docs/install.md`), in the site's generated
      skill catalogue, and in `README.md`'s on-demand skill list beside `/aid-summarize`. The
      rendered catalogue entry reads as a complete one-paragraph summary next to its siblings —
      and if it does not, it is raised against feature-010, whose `SKILL.md` `description` the
      generator reads, rather than patched in the generated page.
- [ ] **The toolkit diagrams and their contract move together.** The skill appears in every
      diagram `docs/diagram-content-reference.md` names as a skill-addition trigger, including
      `README.md`'s hand-authored `R1` diagram (which has no sync step), and the reference itself
      is updated in the same change.
- [ ] **Automated coverage reaches parity with `/aid-summarize`.** Suites exercise the skill's
      preflight, its staleness behaviour, and its artifact validation. The named suites from the
      feature SPECs all exist and pass: `test-graph-preflight.sh`, `test-graph-stale-check.sh`,
      `test-graph-read-only.sh`, `test-relationship-schema.sh`, `test-validate-relationships.sh`,
      `test-graph-gap-ledger.sh`, and `test-graph-view-shell.sh`.
- [ ] **The registration suite anchors to the source of truth, not to a sibling.** It confirms the
      skill's canonical definition and every rendered copy exist across all five host profile
      trees and the dogfood tree, and **that assertion compares each tree to the canonical source
      rather than to another tree** — L4's invariant-anchoring rule, and the specific mistake the
      `io_bounds.py` incident was made of.
- [ ] **The full canonical suite passes, run the way the project documents it, locally.** `bash
      tests/run-all.sh` (HOME-pinned) is green on the branch immediately before it ships. This
      must be run locally because the full suite is a master-only gate — feature branches run only
      `installer-tests.yml`, so a direct merge can red-master in ways the branch never saw.
- [ ] **The Knowledge Base describes the toolkit that now exists.** `capability-inventory.md`
      gains the `/aid-graph` capability entry; `module-map.md` gains the `graph/` script area in
      "Script Modules by Area" and the `canonical/skills/aid-graph/` mention;
      `release-tracking.md` gains an `## Unreleased` `[NEW]` item. Plus the deferred drafts:
      `artifact-schemas.md` gains `relationships.md` and the relation-vocabulary contract per that
      doc's own convention for adding an artifact type; `domain-glossary.md` gains an entry only
      if the vocabulary research coined a Concept Spine term (relation names themselves are data
      values, not spine concepts); and `technology-stack.md` / `infrastructure.md` gain the
      entries feature-002 drafted, if a third-party approach or build step was adopted.
- [ ] **feature-010's FR-28 gate closes over both artifacts for the first time.** In delivery-002
      only the `R*` data checks (`R1`–`R5`) had an artifact to run against. Here the full rubric
      runs — the data checks **and** the `V-*` view checks (`V-A` accessibility baseline, `V-C`
      contrast in both themes, and the visual validation) — and it scores the skill's own
      artifacts only, never the Knowledge Base's completeness.
- [ ] **All thirteen features are landed and every §9 acceptance criterion is closed by a named
      delivery.** AC-1–AC-5, AC-11–AC-13 and AC-16–AC-18 in delivery-002; AC-14 in delivery-003;
      AC-6, AC-7, AC-8 and AC-10 in delivery-004; AC-9 and AC-15 in delivery-005. The one
      criterion that remains conditional is FR-26, which cannot be fully satisfied until the Q8
      ledger-retention carve-out lands as a methodology-level change outside work-005 — this gate
      records that state rather than marking it closed.
- [ ] All section-6 quality gates pass: the delivery gate's `grade.sh` run over
      `.aid/.temp/review-pending/` reaches this repository's resolved `minimum_grade` of **A+**
      (`review.minimum_grade` in `.aid/settings.yml`; this work's `minimum_grade: "A+"`), i.e.
      zero findings with Status `Pending` or `Recurred`.

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001, delivery-002, delivery-003, delivery-004, delivery-005 — every
  surface here describes something one of them built, so each can only be written truthfully once
  that delivery has landed
- **Blocks:** -- (none; this is the last delivery)

### Recorded deviation from aid-plan's priority ordering

`aid-plan`'s quality checklist requires deliverables to follow **Must → Should → Could**. This
delivery is **Must**, yet it is sequenced *after* delivery-004 and delivery-005, both **Should**.
That inversion is deliberate and unavoidable rather than an oversight, and it is recorded here for
the same reason delivery-001's not-standalone-functional deviation is recorded.

The reason is that this delivery's content is **derivative by construction**: every test suite,
documentation surface, and Knowledge Base entry it produces describes an artifact another delivery
built. Sequencing it earlier would mean writing tests for code that does not exist and documenting
behaviour not yet decided — which is precisely the failure tech-debt **L4** records, where surfaces
asserted each other and "passed" while all of them were wrong. Its Must priority reflects that the
work is **not optional for shipping**, not that it can start early.

Consequence to hold in view: because delivery-004 and delivery-005 are Should, a decision to defer
either one also defers this Must delivery, and with it FR-28's full-rubric closure. The two Shoulds
are therefore only deferrable *together with* the ship gate, never independently of it.

## Notes

- **Only one of the four discoverability surfaces is generated.** The rest are hand-authored prose
  and hand-drawn diagrams, and the repository has already learned once that hand-authored
  inventories drift. The work is not only to add a name in four places, but to add it in the
  places the project's own maintenance contract says must move together when a skill is added.
- **`docs/diagram-content-reference.md` is a contract, not just a document.** Its maintenance rule
  names which diagrams a skill addition triggers, so updating the reference in the same change is
  part of honouring it rather than a nicety.
- **Count needles versus roster entries.** The `${SKILLS}` count needles in the same documentation
  files belong to feature-012 and landed in delivery-002; this delivery owns the **roster**
  entries. Both must be present for `tests/canonical/test-doc-counts.sh` and
  `site/scripts/gen-reference.mjs` to stay green, so the ship gate is where the two halves are
  confirmed to have met.
- **A skill's own canonical `README.md` never ships.** `canonical/skills/aid-summarize/README.md`
  exists and appears in no install tree, so `canonical/skills/aid-graph/README.md` is maintainer
  documentation for contributors reading `canonical/` and is **not** one of the surfaces that
  satisfies the discoverability criterion.
