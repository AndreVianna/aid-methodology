# Delivery BLUEPRINT -- delivery-001: Lifecycle Machinery, KB Doctrine, and Planning Skills

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-001
> **Work:** work-006-design-phase-skills
> **Created:** 2026-08-09

---

## Objective

Establish the foundation the other thirty-six-skill work stands on, and prove it end to
end on one artifact family. Three things land together because they cannot be verified
apart: the artifact home and the shared three-stage contract (`.aid/design/` plus the
`design-lifecycle.md` / `design-seed.md` / `design-folder-readme.md` templates); the KB
doctrine and conditional-membership change that makes a project-level forward-looking
document admissible at all; and the nine planning skills whose `create` verb is the first
thing to exercise the whole chain — seed written, seed consumed, document created,
registered, and revised. feature-001 and feature-003 are mutually dependent (feature-001
owns membership and doctrine, feature-003 owns document shape, the instances, and the
`document-expectations.md` block text handed back), so they are scoped into one delivery
rather than across two.

## Scope

- **feature-002-design-lifecycle-machinery** — land and correct `.aid/design/`; author the
  three new canonical templates; fix the contract, the seed shape, the region mechanics,
  the skill shape and the class-binding table; refresh the KB `.aid/` tree line.
- **feature-001-kb-doc-set-restructure** — the two doctrine amendments; conditional
  registration of `roadmap.md`, `backlog.md` and `release-tracking.md` across CC-4's four
  surfaces; the `## Unreleased` migration and the `release-aid` rewire; the adopter-facing
  manual drain paragraph.
- **feature-003-planning-artifact-skills** — the nine `design`/`create`/`update` skills for
  roadmap, mvp and backlog, their catalog rows and directories, the on-disk shape of
  `roadmap.md` and `backlog.md`, the `## MVP` region split, and the item flow. **Plus the
  one canonical edit shared with feature-004** — the `aid-config/SKILL.md` amendment naming
  the `create` skills as a second runtime producer of `knowledge.doc_set`. It is assigned
  here rather than to whichever feature happens to land first, and gated below;
  delivery-002 verifies it rather than repeating it.

**Out of scope:** the render to the five profiles, the byte-identity gate, every
count-bearing surface, and the `/aid-summarize` re-run that regenerates `kb.html` — all
deferred to delivery-003 by design (feature-001 SPEC § *Dependencies*, feature-003 SPEC
§ *Dependencies, hand-offs, and sequencing*: the render is run **once**, in feature-006;
feature-001 SPEC § *Sequencing* step 6 defers the `kb.html` half of its own regeneration
step for the same reason — a final-state summary is refreshed once, after the roster
settles). The twelve foundation skills and the fifteen grid /
brainstorm skills are delivery-002. `quality-gates.md`'s registration is feature-004's, not
this delivery's. Automating the adopter release drain as a canonical skill is out of scope
work-wide and routed to tech-debt.

## Gate Criteria

- [ ] `.aid/design/` is on the work branch with both files; the landed `README.md` is
      byte-identical to `canonical/aid/templates/design-folder-readme.md`, names no
      `/aid-interview`, carries no unqualified deletion statement, presents all four
      lifecycle entries, and routes no reader to a document AID does not install.
- [ ] The three new canonical templates exist and this feature's shipped footprint is
      additive only: no installer library, no engine, no scaffolding file and no `SKILL.md`
      is modified by feature-002, and the first-use acquisition rule is written in the
      canonical path form the render-time path rewriter resolves on all five profiles.
      **Evaluated over feature-002's own commit range, never over the branch** — its
      oracle (feature-002 SPEC § *Verification*, G3) says so itself, and this delivery also
      carries feature-001 (which edits `concern-model.md`, `domain-doc-matrix.md`,
      `document-expectations.md` and both `kb-*.sh` twins) and feature-003 (which adds nine
      `canonical/skills/*/SKILL.md` files), so a branch-wide diff makes the criterion
      meaningless. The range is established when tasks are cut: feature-002's commits are
      the ones ordered first inside this delivery (see Notes), and the diff is
      `<first-parent-before>..<last>` over that block, restricted to
      `-- lib/ canonical/ install.sh install.ps1`.
- [ ] `design-lifecycle.md` is class-scoped and self-sufficient: every rule it states has
      exactly one row in its binding table, no rule binds a population with no
      implementation site, `design-seed.md`'s headings are fixed and anchorable, and the
      readiness detection rule is codeable from the contract alone.
- [ ] Doctrine is amended in **both** carriers (canonical `concern-model.md` and the
      dogfood `authoring-conventions.md`), including admission of **skill-created**
      conditional documents; and `roadmap.md`, `backlog.md` and `release-tracking.md` each
      occupy all four of CC-4's registration surfaces, in both `_dim_of_filename` twins.
- [ ] The seed does not move: no test script under `tests/canonical/` or
      `site/scripts/__tests__/` is edited, none of the three documents enters
      `synth_default_seed`'s ownership map, no file is added under
      `canonical/aid/templates/`'s `knowledge-base/` subtree, and every named seed-count
      assertion is green **unmodified**.
- [ ] `release-tracking.md` carries no `## Unreleased` section and no prose describing one,
      in every carrier this delivery writes — the section and its frontmatter/lede, plus
      the two script-regenerated carriers (`INDEX.md`, `relationships.md`); `release-aid`
      drains committed items from `backlog.md` at tag time and its dead `## Change Log`
      instruction is gone; the equivalent **manual** drain step is documented on a canonical
      surface adopters actually receive. The fourth carrier, `.aid/knowledge/kb.html`, is
      **not dropped and not hand-patched**: it is regenerated by the single `/aid-summarize`
      re-run in delivery-003, and feature-001 AC-6's `grep -c Unreleased .aid/knowledge/kb.html`
      → `0` conjunct is evaluated at *that* gate (feature-001 SPEC § *Sequencing* step 6 and
      § *Dependencies*, *Outbound*). One authored ~24-minute run, placed where the KB has
      stopped moving — not two.
      **The `release-aid` conjunct is split the same way, and the split is named here rather
      than left implicit.** Its *textual* half is evaluated at this gate — `release-aid`'s
      § 3.1 names `backlog.md` as the drain source, `grep -c Unreleased` over that file
      returns `0`, and the dead `## Change Log` instruction is gone (feature-001 AC-7, AC-8;
      task-009). Its *runtime* half — that the drain actually moves items at tag time —
      cannot be evaluated at any gate inside this work, because it needs a real release cut.
      Its evaluator is `release-aid`'s **own Step 9 close-out check**, rewritten in task-009
      to verify that the drained items are absent from `backlog.md` and present in the new
      `release-tracking.md` version section, and it fires on the first `/release-aid` run
      after this work merges. Named, not dropped (feature-003 V19; task-023 § Scope).
- [ ] Nine skill directories and nine complete, hand-authored catalog rows exist; re-running
      `build-shortcut-skills.py` overwrites no body.
- [ ] For each of roadmap, mvp and backlog the `design → create → update` sequence
      completes with the seed consumed at `create`; `## MVP` survives its neighbour and
      `/aid-*-mvp` writes only that section; `/aid-create-mvp` against an absent
      `roadmap.md` routes to `/aid-create-roadmap` rather than creating it or stopping
      silently.
- [ ] Creation registers the document **in the same run** and nothing else registers it
      (CC-1, CC-2): the `knowledge.doc_set` entry at the presence value CC-1 fixes, and the
      `README.md` Completeness row, are written by the `create` skill; a project that never
      runs one has neither document nor either registration, and no gate reports a missing
      or hollow document.
- [ ] The `aid-config/SKILL.md` amendment is **landed here, by feature-003** — not left to
      "whichever feature lands first". `canonical/skills/aid-config/SKILL.md:160` today reads
      *"`knowledge.doc_set` and `knowledge.term_exclusions` are runtime-written by
      `aid-discover`"*; after this delivery that line also names the `create` skills as a
      second runtime producer of `knowledge.doc_set`, written once and naming **both**
      producers, so feature-004 (delivery-002) verifies rather than repeats. The plan's own
      ordering already determines the owner — delivery-001 runs first — and this criterion
      is what stops both sides deferring to each other with every gate green.
      *Oracle:* `grep -n 'aid-discover' canonical/skills/aid-config/SKILL.md` at that row
      also matches a `create`-skill mention on the same line.
- [ ] Both new instances comply with C-3 (no `## Change Log`, no `changelog:` field, no work
      id or work-folder path); an item lives in exactly one of the three flow documents;
      `update` asks for derived outputs every run and writes no tracking metadata; no skill
      drives `phase:`; every one of the nine descriptions carries the negative routes
      assigned to it.
- [ ] All section-6 quality gates pass

## Tasks

Task numbering is GLOBAL across the work; delivery-001 holds task-001..task-025. **The
numbering is allocation order, not execution order** — the `Depends on:` field in each
DETAIL.md, rendered as the execution graph in `PLAN.md § Execution Graph`, is the sole
authority on sequencing.

The edges that run from a lower-numbered task to a higher-numbered one are partitioned into
two causes in `PLAN.md § Execution Graph`, where the partition carries its own invariant. The
graph is acyclic, single-rooted at task-001 and single-leafed at task-020.

Those edges carry the wave interleave, whose run order is: feature-002, then feature-001's
early steps, then feature-003, then feature-001's late steps. feature-001's steps 5 and 6 sit
downstream of feature-003 creating the documents and verifying against them, which is the
hand-off that puts the two features in one delivery. It is a run order, **not** a dependency:
feature-002 does not depend on feature-001, as this file's own § Notes quotes feature-002
denying.

They also carry the delivery's **shared-state** discipline. task-024 produces the throwaway
local render once and task-025 reverts it once; the tasks that need invocable skills consume
it read-only. Verified mechanically over declared **read sets and write sets stated
as concrete paths** for all 25 tasks, with two accesses conflicting when one path is a prefix
of the other: for every pair where one task's read set meets another's write set, **or** their
write sets meet, one is a transitive ancestor of the other — zero unordered pairs of either
kind, and no wave carries a conflict. **A resource's granularity is fixed by its coarsest
reader, not chosen**: because a tree-scoped reader exists for the three render trees, for
`canonical/` and for `canonical/skills/`, each is tree-scoped, and task-009's single-file edit
to `.claude/skills/release-aid/SKILL.md` therefore conflicts with readers that never name it.
A per-skill model suppressed exactly that true positive in an earlier revision, and a
write-only model was blind to the task-017/task-018 reader/writer race before it.

**Where the sequencing record lives.** `PLAN.md § Execution Graph` holds the dependency table,
the `wave-map` and the `rw-sets` block; this section names them rather than reproducing their
contents.

Several tasks commit while the render is live. Two rules keep that safe, each carried as an
acceptance criterion by the tasks it binds: every committer **stages explicit paths only**
(never `git add -A` / `git add .` / `git add -u` / `git commit -a`), and task-025 **restores
the three trees to current `HEAD`, never to task-024's manifest bytes** — which is what stops
the teardown reverting task-009's committed `.claude/skills/release-aid/SKILL.md`, the one
delivered artifact that lives inside a tree task-025 restores wholesale.

| Task | Type | Title |
|------|------|-------|
| task-001 | DOCUMENT | Landed `.aid/design/` folder and its canonical README template |
| task-002 | DOCUMENT | `design-seed.md` -- the anchorable seed-shape template |
| task-003 | DOCUMENT | `design-lifecycle.md` -- the three-stage `design -> create -> update` contract |
| task-004 | DOCUMENT | Rule-binding table that class-scopes the lifecycle contract |
| task-005 | TEST | Shipped-footprint audit of the lifecycle machinery over its own commit range |
| task-006 | DOCUMENT | KB doctrine amendment admitting project-level governance documents |
| task-007 | DOCUMENT | Conditional matrix rows and concern-model entries for roadmap, backlog and release-tracking |
| task-008 | IMPLEMENT | Filename-to-spine-dimension arms for the three documents in both KB script twins |
| task-009 | DOCUMENT | `release-aid` drain rewired onto `backlog.md` |
| task-010 | DOCUMENT | Three `design` planning-artifact skills and their catalog rows |
| task-011 | DOCUMENT | `/aid-create-roadmap`, the `roadmap.md` shape, and the second `doc_set` producer |
| task-012 | DOCUMENT | `/aid-create-backlog`, the `backlog.md` shape, and the item-promotion mechanism |
| task-013 | DOCUMENT | `/aid-create-mvp` and the `## MVP` region split inside `roadmap.md` |
| task-014 | DOCUMENT | Three `update` planning-artifact skills, completing the nine-row set |
| task-015 | DOCUMENT | This repository's `roadmap.md` instance, its `## MVP` section and its registration |
| task-016 | TEST | Behavioral verification of the `design` and `create` stages, and the deferred acquisition oracles |
| task-017 | DOCUMENT | The three `document-expectations.md` blocks and the adopter drain paragraph |
| task-018 | MIGRATE | Retirement of `## Unreleased` and the move of its items into `backlog.md` |
| task-019 | DOCUMENT | Regeneration of the two script-generated Knowledge Base summaries |
| task-020 | TEST | Seed-immobility and registration audit for the Knowledge Base doc-set change |
| task-021 | DOCUMENT | This repository's `backlog.md` instance and its registration |
| task-022 | TEST | Byte-discipline verification of the `## MVP` region split |
| task-023 | TEST | Behavioral verification of the `update` contract across the nine skills |
| task-024 | CONFIGURE | Throwaway local dogfood render that makes the nine new skills invocable |
| task-025 | CONFIGURE | Reverted local render and a working tree restored to its pre-render state |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** delivery-002

## Notes

- Internal ordering is fixed by the member specs and should be honored when tasks are cut:
  feature-002 § *Sequencing, dependencies, and shipped-behavior impact* (folder → seed shape
  → contract → binding table) runs **first in this delivery**, because features 003, 004 and
  005 all bind its contract — feature-002 SPEC § *Sequencing…* states *"Blocks features 003,
  004, 005"* and feature-001 is **not** in that set. An earlier draft of this note said
  feature-002 "gates the other two, since features 001, 003 and 004 all bind its contract";
  both source specs deny the feature-001 half — feature-002's own § *Sequencing…* says
  *"Depends on feature-001: no… No ordering constraint runs from feature-001 to this one"*,
  and feature-001 § *Dependencies* says it is *"Independent of feature-002 — touches no
  skill machinery"*. So feature-002 gates **feature-003** inside this delivery, and its
  first position is a convenience for feature-003 and for delivery-002, not an obligation
  feature-001 imposes. Within the pair, feature-001 § *Sequencing* runs doctrine → registration
  surfaces → the `## Unreleased` migration, then **pauses**: its steps 5 and 6 (the
  shape-derived halves of the `### roadmap.md` and `### backlog.md` blocks, then the
  regeneration of the two *script*-generated summaries, `INDEX.md` and `relationships.md`)
  sit downstream of feature-003 creating the documents. That hand-off is the reason the two
  features share a delivery. `kb.html` is **not** in that step: it is the one summary whose
  regeneration is an authored `/aid-summarize` run, and it happens once, in delivery-003.
- feature-003's own internal order: document shape first (nothing can be authored before
  it), then the three `design` skills, then `create`, then `update`.
- Three stale count comments inside `shortcut-catalog.yml` are shared with features 004 and
  005 and are deliberately **not** edited here — they are handed to delivery-003 so three
  features do not collide on one file. delivery-003 names them in its Scope and carries a
  criterion for all three, which is what makes the hand-off a transfer rather than a drop.
- **How the behavioral criteria above are exercised.** Criteria 8 and 9 require running the
  new skills, but the render to the five profiles is deferred to delivery-003, so at this
  gate the skills exist only under `canonical/` and are invocable from no profile. The
  execution path is a **local render into the dogfood tree** — `build-shortcut-skills.py`
  then the full `run_generator.py`, then resync `.claude/` from `profiles/claude-code/` —
  run as a throwaway, **not committed**, and re-done for real in delivery-003. The
  alternative, invoking the bodies from `canonical/` by hand, does not exercise the
  render-time path rewriter and so cannot back criterion 2's acquisition-rule clause. This
  is the same shape feature-002 SPEC § *Verification* labels *"review (manual run; the 36
  skills do not exist until features 003–005)"* on B3, E1, E2 and E3. Whichever path a task
  takes, it must leave `git status --porcelain profiles/ .claude/ .cursor/` clean at this
  gate — delivery-003 owns the committed render (C-5: one full run, never a partial).
- Cross-feature rules are governed by REQUIREMENTS FR-11 (CC-1..CC-9): refer to a contract,
  never restate it.
