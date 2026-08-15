# Delivery BLUEPRINT -- delivery-002: Foundation and Grid Skills

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-002
> **Work:** work-006-design-phase-skills
> **Created:** 2026-08-09

---

## Objective

Complete the roster. Twelve foundation skills carry the technical standards a project
settles early — architecture, stack, testing strategy, CI/CD — from a `.aid/design/` seed
into whichever KB document realizes their concern in the project's domain, including on a
brownfield project whose destinations are already populated. Fifteen further skills make
the `design` stage uniform across the whole existing catalog (fourteen grid rows) and add
the one exploratory skill with no `create` counterpart (`/aid-brainstorm`), composing
`design` with the existing `create` doorways through a single additive engine read.
feature-004 and feature-005 are mutually dependent on description text — feature-004 needs
bare `/aid-design`'s narrowing, feature-005 needs three foundation counterparts — so they
are scoped into one delivery rather than across two.

## Scope

- **feature-004-foundation-artifact-skills** — twelve skills and rows; destination
  resolution by concern rather than filename; the four content-collision assignments;
  per-artifact content rules for the eight `create`/`update` skills; `quality-gates.md`'s
  completion across CC-4's four registration surfaces; the Conformance-Lane obligations.
- **feature-005-design-grid-and-brainstorm** — fourteen `design` rows and doorways derived
  from the paired create/update set; `/aid-brainstorm`; FR-10's one additive read in
  `canonical/aid/templates/shortcut-engine.md` plus the two hand-authored reads that reach
  the `document` pair; the five description edits to shipped skills.

**Out of scope:** the render, the byte-identity gate, every count-bearing assertion, and
the whole-set mutual-routing sweep — all deferred to delivery-003, because each is an
aggregate over the finished set of thirty-six (feature-005 SPEC § *Boundaries*). Modifying
any of the 28 existing paired `create`/`update` doorways beyond the two `document` files;
a `design` family scaffolding file; changing bare `/aid-design`'s behavior; and removing
`alias_of` are all out of scope work-wide. Of those, bare `/aid-design` is the one this
delivery could actually break — feature-005 edits its frontmatter here — so it is **also**
a gate criterion below rather than out-of-scope prose alone.

## Gate Criteria

- [ ] Twenty-seven skill directories and twenty-seven complete catalog rows exist — twelve
      foundation, fourteen grid, one `/aid-brainstorm` — each with `name` equal to its
      directory and to its frontmatter `name:`, `alias_of: null`, and `repurpose: true` so
      the build helper does not overwrite a hand-authored body.
- [ ] The grid selection is exactly the artifacts carrying **both** a `create` and an
      `update` row in the catalog as it stood before this work, verified in both
      directions; skills with no catalog row acquire none. It is a positive selection, and
      no "unpaired artifact" exclusion rule is asserted anywhere (CC-8).
- [ ] FR-10's engine read is one additive, conditional, non-mutating bullet at CAPTURE
      Step 2: with a seed present the doorway loads it as prior context; with no seed
      present engine behavior is unchanged. The `document` pair, which never runs the
      engine, gets the equivalent one-line read in both of its hand-authored bodies, so the
      read reaches all fourteen paired artifacts rather than thirteen.
- [ ] The brownfield sequence completes: in this repository as it stands,
      `design → create` reaches the realization event and consumes the seed although the
      destination is populated. `create` gates on its **seed** and on one property of the
      destination that is *not* about how full it is — never on the destination being
      populated. Each `create` state enumerates exactly the three refusal conditions
      feature-004 SPEC § *Verification* (V27) fixes — seed-absent, non-empty
      `## Open questions`, and destination `source: generated` — **and no fourth**: no
      destination-size, emptiness or `hand-authored` gate exists anywhere. The exclusion
      list is `hand-authored`, not `source:`; `source: generated` is the third **mandated**
      condition, and forbidding it would delete a refusal the spec requires. V27's own grep
      set is the check: `empty|populated|non-empty|hand-authored|line count` over each
      CREATE state returns nothing.
- [ ] `update` requires no seed and consumes one when present (CC-3): it completes and
      writes the destination with the seed absent, and with the seed present it consumes it
      and carries its current direction into the destination.
- [ ] The four contested content topics are owned as assigned: no `create` skill writes
      another artifact's destination document; `## Contents` stays consistent with the body
      in both directions after any write; and no KB frontmatter is forged or restamped
      (`source:` and `approved_at_commit:` unchanged, frontmatter lint green).
- [ ] `quality-gates.md` occupies all four of CC-4's registration surfaces with concern
      `C6`, and a document created by a `create` skill is registered in the same run
      (CC-2): the `doc_set` entry at CC-1's presence value with the doc's matrix owner,
      plus the `README.md` Completeness row and its doc-set count.
- [ ] No seed-count assertion moves: this delivery adds no file under
      `canonical/aid/templates/knowledge-base/`, and the named doc-set and matrix suites
      are green with their own files unchanged.
- [ ] Every description this delivery writes carries its assigned negative route, and names
      no neighbour it was not assigned — the twelve foundation sides, both sides of the
      pairs owned end to end here, and the five edits to shipped skills. The whole-set pair
      check is delivery-003's.
- [ ] **Bare `/aid-design`'s behavior is unchanged** (feature-002 AC-9). This delivery is
      where it can fail, because feature-005 § *Description edits and negative routing*
      edits that file here — its `description` and `argument-hint` — and nothing else in
      the work touches it. *Oracle:*
      feature-002 SPEC § *Verification*, G1 — `git diff master -- canonical/skills/aid-design/SKILL.md`
      shows hunks confined to the YAML frontmatter block and **no hunk touching the four
      `DESIGN.md` sites**. A whole-file `--exit-code` diff is the wrong shape and would be
      unsatisfiable by construction. Placed as a checkbox rather than left in Out-of-scope
      prose: an out-of-scope sentence is not evaluated at any gate, and this is the one
      shipped-behavior claim in the delivery that a wrong edit would silently break.
- [ ] The twenty-seven bodies bind the shared contract rather than forking it: each names
      `canonical/aid/templates/design-lifecycle.md` and restates none of its rules; every
      `design` skill writes only within `.aid/design/`; no skill drives `phase:`; and each
      `update` asks for derived outputs unconditionally, every run, storing no answer.
- [ ] All section-6 quality gates pass

## Tasks

Task numbering is GLOBAL across the work; delivery-002 holds task-026..task-049, continuing from
delivery-001's task-025. **The numbering is allocation order, not execution order** — the
`Depends on:` field in each DETAIL.md, rendered as the execution graph in
`PLAN.md § Execution Graph`, is the sole authority on sequencing. Here the two coincide: ids were
allocated in execution order, so delivery-002 contributes **no** edge from a lower-numbered task
to a higher-numbered one, and the partition of such edges in `PLAN.md § Execution Graph` is
unchanged by this delivery.

delivery-002 enters the graph through a single edge, `026 → 020` — delivery-001's leaf. That is
what makes every delivery-001 task a transitive ancestor of every delivery-002 task, and it is a
real read/write serialisation rather than a formality: task-020 audits
`canonical/aid/templates/` whole, and task-026 writes into that tree.

The run order is feature-005's three *edit-what-exists* tasks, then feature-005's fifteen new
doorways, then feature-004's twelve, then the render, the behavioral verification, the revert and
the static sweep. Two ordering facts drive it and neither is cosmetic: every one of the
twenty-seven bodies is modelled on `canonical/skills/aid-design/SKILL.md`, whose frontmatter
task-028 rewrites; and feature-004 §1b places its four `design` rows *"in the G3 block after
feature-005's fourteen"*. Inside feature-004, §12's internal order is followed exactly —
destination-resolution `design`, then `quality-gates.md`'s registration, then `create`, then
`update`.

They also carry the delivery's **shared-state** discipline. task-039 produces the throwaway local
render once and task-048 reverts it once; the tasks that need invocable skills consume it
read-only. Verified mechanically over declared **read sets and write sets stated as concrete
paths** for all 49 tasks in both deliveries, with two accesses conflicting when one path is a
prefix of the other: for every pair where one task's read set meets another's write set, **or**
their write sets meet, one is a transitive ancestor of the other — zero unordered pairs of either
kind, and no wave carries a conflict. The four verification tasks at wave 43 are the delivery's
only parallelism, and they earn it by confining every run to a scratch project under `mktemp -d`,
which is why all four declare an empty write set; the four lifecycle tasks before them do not,
because they allocate `work-NNN` folders in this repository's tracked `.aid/works/` tree.

**Where the sequencing record lives.** `PLAN.md § Execution Graph` holds the dependency table,
the `wave-map` and the `rw-sets` block for this delivery; this section names them rather than
reproducing their contents.

Four tasks mutate this repository's Knowledge Base and restore it. task-040 through task-043 each
run one artifact's whole `design → create → update` lifecycle against the real populated
destinations feature-004 AC-3 and feature-002 E2 are scoped to, and each carries its own
restoration criterion to current `HEAD`; task-048 confirms rather than repairs, and records any
residue it has to fix. No task in the render window commits anything, and none uses
`git add -A` / `git add .` / `git add -u` / `git commit -a`.

## Dependencies

- **Depends on:** delivery-001
- **Blocks:** delivery-003

## Notes

- What delivery-001 must have landed first, and why: the `design-lifecycle.md` contract and
  the `design-seed.md` shape (both features bind them), the landed `.aid/design/` folder
  (every one of these skills reads or writes a path inside it, so none can be **exercised**
  before it lands — though bodies and rows can be **authored** earlier), and feature-001's
  skill-created-conditional doctrine amendment, without which a KB review can reject a
  document feature-004 legitimately created.
- `design-seed.md` is **frozen** once this delivery starts: feature-005's engine read and
  its two `document` doorway reads consume seeds in that shape.
- feature-004's internal order: destination resolution and the collision assignments first
  (authoring any `create` before they are settled forks them four ways), then `design`, then
  `create`, then `update`.
- Both features append rows to the single `canonical/aid/templates/shortcut-catalog.yml`.
  The rows are append-only and disjoint, so they do not conflict textually — but the
  generator is **not** run here (C-5's full render is delivery-003's single run), and the
  catalog's own stale count comments are handed to delivery-003 for the same reason, where
  they are a named Scope item with their own criterion.
- One canonical edit is shared with feature-003 (delivery-001): the `aid-config` amendment
  naming the `create` skills as a second runtime producer of `knowledge.doc_set`. The
  ownership is **not** "whichever feature lands it" — the plan's ordering settles it, and
  delivery-001 carries the criterion that lands it. This delivery **verifies** rather than
  repeats: `canonical/skills/aid-config/SKILL.md`'s `knowledge` row already names both
  producers when feature-004 arrives, and feature-004 adds nothing to that line. A second
  write there is a defect, not a duplicate.
- **How the behavioral criteria above are exercised.** Criteria 4 and 5 require running the
  new skills while the render to the five profiles is deferred to delivery-003, so the same
  execution path delivery-001's Notes state applies verbatim: a throwaway local
  `build-shortcut-skills.py` + full `run_generator.py` + `.claude/` resync, **not
  committed**, with `git status --porcelain profiles/ .claude/ .cursor/` clean at this gate.
  Criterion 4's brownfield sequence in particular is feature-002 SPEC § *Verification* E2,
  which that spec already labels a manual run for exactly this reason.
