# task-014: Three `update` planning-artifact skills, completing the nine-row set

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-014/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-013

**Scope:**
- Source spec: `features/feature-003-planning-artifact-skills/SPEC.md` §6c, §6d, §4's
  routing table; feature-002 §3a's `create`/`update` table and §3d; REQUIREMENTS FR-8, CC-3,
  CC-5. These skills need a destination that exists, so they are last in feature-003's
  internal order.
- Author `canonical/skills/aid-update-roadmap/SKILL.md`, `aid-update-mvp/SKILL.md` and
  `aid-update-backlog/SKILL.md` plus their three catalog rows (`verb: update`,
  `default_type: DOCUMENT`, `group: G5`, `alias_of: null`, `repurpose: true`, §1's `intent`
  strings verbatim), on feature-002 §3e's skill shape with `phase` not driven.
- **Owned regions** (§6c): `/aid-update-roadmap` -- `roadmap.md` minus `## MVP`, adding,
  revising and superseding direction entries and moving an entry between horizon sections,
  never touching `## MVP` and leaving the `MVP` index entry in place whether or not the
  section exists; `/aid-update-mvp` -- `roadmap.md`'s `## MVP` only, and it **may create the
  region** when the document exists without it, revising the slice and its `Status`
  including the transition to `Shipped <version>`; `/aid-update-backlog` -- `backlog.md`,
  re-prioritizing, adding items, promoting confirmed `tech-debt.md` rows and deleting them
  there in the same run, and keeping `## Next Release` in step with what is committed.
- **CC-3**: each reads its artifact's `.aid/design/` seed when one is present and **consumes
  (deletes) it**, while never *requiring* one. This is what gives a routed seed its consumer:
  when `create` routes it has realized nothing, so the seed survives and the `update` run it
  routes to becomes the realization event.
- **FR-8 / feature-002 §3d**: ask the user which previously created outputs to update
  **every run** -- no frontmatter backlink, no manifest, no registry, no state between runs --
  and write **no tracking metadata** into any output.
- **Absent-destination routing goes to the document's owner**, not to the skill's own
  `create` counterpart: `/aid-update-roadmap` **and** `/aid-update-mvp` both route to
  `/aid-create-roadmap` (a region-owning skill routes to the document's owner -- CC-5);
  `/aid-update-backlog` routes to `/aid-create-backlog`. Nothing is written on the way out.
- Both mvp verbs are bound by the same byte discipline: `update` is a writer too, and the
  table above grants it the power to create the region, so an oracle exercising only
  `create` would leave the more dangerous writer untested.
- Out of scope: the shape of either document, fixed in task-011 and task-012; the release
  drain (task-009 / task-018); and the catalog's three stale count comments (delivery-003).

**Acceptance Criteria:**
- [ ] **V1 complete**: `ls -d canonical/skills/aid-{design,create,update}-{roadmap,mvp,backlog}`
      -> 9, and
      `grep -cE '^  - name: aid-(design|create|update)-(roadmap|mvp|backlog)$' canonical/aid/templates/shortcut-catalog.yml`
      -> `9`
- [ ] **V3 complete**: all nine rows carry the eight fields, `default_type` in the closed
      8-enum and `group` in {G3, G4, G5}; `test-catalog-dirs-parity.sh` green
- [ ] **V2 complete**: running `build-shortcut-skills.py` leaves
      `git diff --exit-code canonical/skills/aid-*-{roadmap,mvp,backlog}/` clean across all
      nine, and `grep -rL 'shortcut-engine'` over the nine `SKILL.md` files lists all nine
- [ ] V17's semantics are stated in the bodies: `/aid-update-mvp` routes to
      `/aid-create-roadmap`. A body naming `/aid-create-mvp` there is the failure this
      criterion exists to catch
- [ ] Each body asks the derived-outputs question unconditionally, every run, and no body
      reads or writes a stored list of outputs anywhere (FR-8)
- [ ] Each body consumes its seed when one was read and never refuses for want of one (CC-3)
- [ ] **V25 complete**: all nine `description` values name every neighbour §6d assigns them
      and no neighbour it does not -- 9 of 9 by grep. Every pair in §6d's table is internal to
      this feature, so all nine sides are checkable here rather than deferred (CC-9)
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean, and no count comment
      inside `shortcut-catalog.yml` is edited
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
