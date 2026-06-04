# Plan — work-001-agents-review

> First-principles redesign of the AID agent roster. Two features, one-directional
> dependency, split at the single human approval gate between *deciding* the roster and
> *executing* the migration. Both Must-have. Sequenced as two deliverables so the design is
> approved and frozen before any file in the repo is mutated.

## Deliverables

### delivery-001: Approved roster design
- **What it delivers:** A complete, reviewable agent-roster **decision** — the needs→role
  matrix (demand), the current-state audit of all 22 agents (supply), the target roster with
  its chosen definition-format + generation approach, and the old→new migration map. The unit
  of value is a frozen, human-approved design that downstream execution consumes
  deterministically. No repo files are mutated.
- **Features:** feature-001-roster-design
- **Depends on:** —
- **Priority:** Must

### delivery-002: Roster rollout
- **What it delivers:** The repository migrated to the approved roster — new agent definitions
  authored, every dispatch site (SKILL.md, references, templates, recipes) rewired, all five
  install trees regenerated, KB + agent-count docs updated, and a clean repo-wide consistency
  sweep. End state: the methodology runs on the new roster and the repo builds/validates with
  zero dangling agent references.
- **Features:** feature-002-roster-rollout
- **Depends on:** delivery-001
- **Priority:** Must

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | Broad rewire (≈300+ agent refs incl. aid-discover/aid-execute) + 5-tree regeneration could leave dangling refs or break the build | H | delivery-002 gates on FR9 word-boundary consistency sweep across canonical source + all five rendered trees, plus the determinism gate (`verify_deterministic.py`) and a buildable-repo check — AC4/AC5 |
| 2 | Substring collisions during rewire/sweep (`architect` ⊂ `discovery-architect`) | M | delivery-002 mandates word-boundary matching for both rewire and sweep (feature-002 §Rewire Mechanism, B4) |
| 3 | Repo-root `.claude/` dogfood tree has no in-repo sync mechanism, so it is scoped out of the FR9 sweep | L | Documented out-of-band exclusion (feature-002 B2); re-include the sweep if a future feature adds a real dogfood-sync step |
| 4 | Concurrent agents sharing the main checkout (work-002, work-003) could collide with edits | M | This work is isolated in its own git worktree (`.claude/worktrees/work-001-agents-review`); rollout edits happen there, not the shared checkout |

## Notes on sequencing

- **Why two deliveries, not one:** feature-001 terminates at the work's single human approval
  gate; the migration map it produces is the deterministic input contract for feature-002.
  Splitting here makes the approval a delivery boundary and keeps "decide" reviewable before
  any irreversible "execute" begins. Each delivery is a coherent, independently reviewable unit
  of value; the dependency flows one direction (001 → 002), no cycles.
- **No deferral:** both Ready features are assigned; nothing deferred.

## Execution Graph

Task numbering is global and sequential across both deliveries. Each task = one
agent session = one reviewable unit, exactly one type. Tasks in the same wave
have no dependency on each other and may run in parallel.

### delivery-001: Approved roster design (feature-001-roster-design)

| Task | Type | Title | Depends on |
|------|------|-------|------------|
| task-001 | RESEARCH | Build the needs→role matrix (demand, FR1) | — |
| task-002 | RESEARCH | Audit all 22 existing agents (supply, FR2) | — |
| task-003 | DESIGN | Derive target roster + format/generation decision (FR3) | task-001, task-002 |
| task-004 | DESIGN | Produce the old→new migration map (FR4) | task-003 |
| task-005 | DOCUMENT | Consolidate artifacts + self-consistency check (approval gate) | task-004 |

- **Wave 1 (parallel):** task-001, task-002
- **Wave 2:** task-003
- **Wave 3:** task-004
- **Wave 4:** task-005 → human approval gate (freezes the roster for delivery-002)

### delivery-002: Roster rollout (feature-002-roster-rollout) — depends on delivery-001

| Task | Type | Title | Depends on |
|------|------|-------|------------|
| task-006 | IMPLEMENT | Author new agent definitions in decided format (FR5) | task-005 |
| task-007 | REFACTOR | Rewire aid-discover dispatch cluster (FR6) | task-006 |
| task-008 | REFACTOR | Rewire aid-execute dispatch cluster (FR6) | task-006 |
| task-009 | REFACTOR | Rewire remaining canonical/skills mid+tail — SKILL.md + all references/*.md (FR6) | task-006 |
| task-010 | REFACTOR | Rewire non-skill SOURCE surfaces: templates + recipes + scripts + rules + EMISSION-MANIFEST + aid-generate exception (FR6) | task-006 |
| task-011 | IMPLEMENT | Fix aid-generate's own stale references (FR7) | task-010 |
| task-012 | CONFIGURE | Regenerate all five install trees (FR7) | task-011 |
| task-013 | DOCUMENT | Update KB + agent-count/tier docs (FR8) | task-006 |
| task-014 | TEST | Repo-wide consistency sweep + determinism + build (FR9) | task-012, task-013 |

- **Wave 5:** task-006 (precondition: delivery-001 approved)
- **Wave 6 (parallel):** task-007, task-008, task-009, task-010, task-013
  (the four rewire clusters touch disjoint surfaces; task-013 derives values
  from the new roster, not the rendered trees, so it runs alongside)
- **Wave 7:** task-011 (generator stale-ref fix; ordered after task-010 so the
  aid-generate SOURCE-exception is rewired before its code is corrected)
- **Wave 8:** task-012 (regeneration; consumes all rewired SOURCE + the fixed generator)
- **Wave 9:** task-014 (terminal gates — must run after both regeneration (012)
  and KB updates (013))

Note: task-013 (Wave 6) and task-012 (Wave 8) both feed the terminal sweep
(task-014); task-013 may complete any time after task-006 and is shown in Wave 6
for earliest-start, but only gates task-014.
