# task-038: Four foundation `update` doorways that require no seed and consume one when present

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-038/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-002

**Depends on:** task-037

**Scope:**
- Source spec: `features/feature-004-foundation-artifact-skills/SPEC.md` §1a (the four `update`
  rows), §6d (what still discriminates `create` from `update`), §7's preamble (the per-artifact
  rules bind **both** members of each pair, and `update` additionally binds §4's targeted-edit
  guard, FR-8's asking obligation and §7a's frontmatter invariants), §7b--§7f (the four content
  rules, read from the `update` side), §9 (the lane obligation `update` must **not** discharge),
  §10. It binds feature-002 §3g's **Class 1** column, §3d, and REQUIREMENTS **CC-3** and **CC-6**
  by reference.
- **Four in one task, because §7 makes them four readings of rules already authored.** Each
  `update` shares its artifact's destination, region and content rule with the `create` task-035,
  task-036 or task-037 already landed; what is new per body is small and identical in shape. It
  follows task-037 because §12's internal order puts `update` last -- it needs a destination that
  exists, and under CC-3 it is also the consumer of any seed `create` routes to it.
- Author four hand-authored bodies --
  `canonical/skills/aid-update-{architecture,stack,testing-strategy,cicd}/SKILL.md` -- on
  feature-002 §3e's shape (`INTAKE -> UPDATE -> VERIFY -> PRESENT -> DONE`; Work Initiation Gate
  allocation with `pipeline.path: lite`, `initiator: aid-update-<artifact>`, **`phase` not
  driven**; `aid-architect` tiered, verifier tier >= producer tier; **full verify**), and append
  four rows to `canonical/aid/templates/shortcut-catalog.yml` at the **end of the G5 block** (§1b):
  `verb: update`, `artifact: architecture|stack|testing-strategy|cicd`, `alias_of: null`,
  `default_type: DOCUMENT`, `group: G5`, the `intent` string §1a supplies verbatim,
  `repurpose: true`.
- **The discriminator, written into every body** (§6d): `update` **requires no seed** -- the user's
  stated change in that run is a sufficient input -- and it **reads and consumes one when present**
  (CC-3), carrying its `## Current direction` into the destination. Both halves are load-bearing in
  opposite directions: a body that refuses without a seed is wrong, and so is one that ignores a
  seed sitting beside it.
- **Destination resolution when there is no seed to read it from** (§7): with no seed, the body
  applies §3a's concern rule itself at INTAKE -- resolve the concern against `.aid/settings.yml`
  `knowledge.doc_set`, falling back to the domain matrix row -- and **confirms the resolution with
  the user before writing**. `/aid-update-architecture` binds C1, `/aid-update-stack` C0,
  `/aid-update-testing-strategy` C6 (**two** documents), `/aid-update-cicd` C8.
- **FR-8's asking obligation, and what makes it observable** (§3d, AC-9): each body's UPDATE state
  carries the derived-outputs prompt as an **unconditional step** -- asked **every run**, never
  inside an `if`/`when` clause -- and stores **no answer**: no frontmatter backlink, no manifest, no
  registry, no state between runs. It writes **no tracking metadata** into any output it updates.
  Stated explicitly because a manifest is the first thing an implementer reaches for.
- **Content rules, per artifact, from the `update` side** (§7b--§7f): the same owned regions and
  the same **must not write** lists as the matching `create`. `/aid-update-stack` remains, among
  these twelve skills, the only writer of framework/tool **versions**, and it is the only one that
  routes a rejected alternative to the project's D doc. `/aid-update-testing-strategy` owns the
  gate **policy** and writes no pipeline stage, and cites no version in **either** C6 document.
  `/aid-update-cicd` writes the stage and no threshold, verdict or waiver rule.
- **Frontmatter invariants** (§7a): the destination's `source:` is **unchanged**, whatever it was --
  neither verb rewrites it; `source: generated` **refuses**; `approved_at_commit:` is **never**
  written or restamped (`canonical/aid/templates/kb-authoring/frontmatter-schema.md:98`;
  `canonical/skills/aid-update-kb/references/state-apply.md:262`); `sources:` gains only what the
  run actually used. **Write discipline** (§4): read whole, edit in place, everything outside the
  edited range byte-identical, never regenerate or restructure
  (`canonical/skills/aid-update-kb/references/state-apply.md:252-258`); adding a `## ` section
  obliges its `## Contents` entry in the same write.
- **The Conformance-Lane obligation `update` must not discharge** (§9): no skill here resolves a
  flagged divergence on its own -- reconciliation is human by the lane's design
  (`canonical/skills/aid-housekeep/references/state-kb-delta.md:183-196`). Each body states that
  it changes **only what the user named in that run**, so a flag the user did not point at
  survives.
- **`update` never creates its destination document.** These four are the maintenance verb; the
  creation paths and their registrations belong to the `create` skills (§6e, §3b, CC-2) and are not
  duplicated here.
- Out of scope: any registration write of `.aid/settings.yml` or `.aid/knowledge/README.md` -- that
  is the `create` skills' same-run effect under CC-2, and a second specification would double-count;
  any file under `canonical/aid/templates/knowledge-base/`; any hand edit to the doctrine files
  task-034 landed; the three stale catalog count comments and the render; and every behavioral run
  (task-040..task-043 for the lifecycle rows, task-046 for FR-8's asking and the lane divergence).

**Acceptance Criteria:**
- [ ] feature-004 V1/V2, this task's share:
      `ls -d canonical/skills/aid-update-{architecture,stack,testing-strategy,cicd}` returns 4
      lines, and
      `grep -cE '^  - name: aid-update-(architecture|stack|testing-strategy|cicd)$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `4`, each with frontmatter `name:` == directory name == row `name`,
      all eight fields, `default_type: DOCUMENT`, `group: G5`, `alias_of: null`,
      `repurpose: true`, and §1a's `intent`. With task-033's four `design` and task-035..037's four
      `create` rows, feature-004's **twelve** rows and twelve directories now exist:
      `ls -d canonical/skills/aid-{design,create,update}-{architecture,stack,testing-strategy,cicd}`
      returns 12 lines and
      `grep -cE '^  - name: aid-(design|create|update)-(architecture|stack|testing-strategy|cicd)$'`
      on the catalog captured to a variable -> `12`
- [ ] Placement: all four rows sit at the **end of the G5 block** -- each row's line number is
      greater than every existing `group: G5` row's, and the G5 block still precedes the G7 comment
      `grep -n '^  # --- G7: Test + Experiment family'`
- [ ] **feature-004 AC-5's static half, both directions.** Each body states that it **requires no
      seed** and completes without one, **and** that it reads and consumes a present seed (CC-3),
      carrying its `## Current direction` into the destination. A body missing either half fails;
      the behavioral oracle (V8) is task-040..task-043's
- [ ] The no-seed destination resolution is written out: with no seed the body applies the concern
      rule at INTAKE -- doc-set first, matrix row as fallback -- and **confirms with the user before
      writing**. A body that resolves silently fails
- [ ] **feature-004 AC-9(a) / V16(a):** in each of the four files, `grep -n 'derived outputs'`
      returns a hit inside the UPDATE state, and that hit is **not** inside an `if`/`when` clause --
      it is an unconditional step. A conditional prompt fails
- [ ] **feature-004 AC-9(c)/(d), static half:** no body specifies a stored answer, manifest,
      registry, backlink or any between-run state, and none instructs the run to write tracking
      metadata (`derived-from`, `source-doc`, `generated-by`, `aid-tracked`) into an output.
      `grep -rniE 'manifest|registry|backlink' ` over the four bodies returns only occurrences that
      **forbid** them
- [ ] The four per-artifact **must not write** lists match their `create` counterparts exactly in
      substance: `aid-update-architecture` excludes versions, pipeline stages/environments and
      rejected alternatives; `aid-update-stack` keeps sole ownership of versions among these twelve
      and routes rejected alternatives to the D doc; `aid-update-testing-strategy` writes no
      pipeline stage and no version in **either** C6 document; `aid-update-cicd` writes no
      threshold, verdict or waiver rule
- [ ] §7a's invariants are stated in each body: `source:` **unchanged**, `source: generated`
      refuses, `approved_at_commit:` never written or restamped, `sources:` gains only what the run
      used -- plus §4's write discipline and the `## Contents` obligation
- [ ] **feature-004 AC-12(b), static half:** each body states that it changes only what the user
      named in that run and does **not** resolve a Conformance-Lane divergence on its own. The
      behavioral half (V23) is task-046's
- [ ] No body specifies creating its destination document: `grep -niE 'create the (document|file)'`
      over the four returns nothing, and each names its `create` counterpart as the route when the
      destination is absent
- [ ] feature-004 V15, this task's share: each `description` names every neighbour §10 assigns it --
      `aid-update-architecture` -> `/aid-create-architecture` and `/aid-document-architecture`;
      `aid-update-stack` -> `/aid-create-stack`, `/aid-create-config`, `/aid-update-config`;
      `aid-update-testing-strategy` -> `/aid-create-testing-strategy`, `/aid-create-test`,
      `/aid-update-test`; `aid-update-cicd` -> `/aid-create-cicd`, `/aid-create-infra`,
      `/aid-update-infra`, `/aid-create-data-pipeline`, `/aid-update-data-pipeline`, `/aid-deploy`
      -- and none names a neighbour §10 does not assign
- [ ] `grep -L 'canonical/aid/templates/design-lifecycle.md' canonical/skills/aid-update-{architecture,stack,testing-strategy,cicd}/SKILL.md`
      is empty, each body drives no `phase:` value, and a reviewer confirms none restates a rule the
      contract states
- [ ] `ls canonical/aid/templates/knowledge-base/*.md | wc -l` captured to a variable is `14`, and
      `git diff --exit-code master -- canonical/aid/templates/kb-authoring/` shows only the hunks
      task-034 and delivery-001 committed
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` and
      `git status --porcelain .aid/knowledge/ .aid/settings.yml` are clean; no count comment inside
      `shortcut-catalog.yml` is edited; `git diff --exit-code -- tests/ site/scripts/__tests__/` is
      clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
