# State-File Consolidation: One STATE.md per Area

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-23 | **3 OQs resolved.** OQ-1 (concurrent-write design): chose **single-writer orchestrator** — matches AID's existing orchestrator-worker pattern (architecture.md §4 #2); aid-execute is the sole writer, sub-agents return results to it, orchestrator serially appends to STATE.md as results arrive; no locking, no event sourcing. OQ-2 (retire vs deprecate templates): **delete outright** — CW2 already executed this; tombstones in install trees would ship as noise to end-user projects. OQ-3 (Monitor stub template timing): **wait until Monitor area matures** — area-STATE pattern is documented; premature design risk; H7 (template missing) remains a known tech-debt item, not blocking. All three moved to Resolved Questions. | aid-specify (OQ resolution) |
| 2026-05-23 | Feature created — codifies the area-based state-file rule (Discovery, Work, Monitor; Monitor deferred). Drives FR2 in `work-003-traceability/REQUIREMENTS.md`. Per the new rule, this feature does NOT have its own per-feature STATE.md — its status will be tracked in `.aid/work-003-traceability/STATE.md` (which itself is created by this feature). | aid-specify (manual draft) |

## Source

- `REQUIREMENTS.md §5` FR2 (state-file consolidation), §1 (objective — direct traceability), §9 FR2 ACs, §10 priority.

## Description

AID's state files have accumulated inconsistently. Each skill independently created its own state file when it needed one (`aid-interview` → `INTERVIEW-STATE.md`; `aid-specify` → per-feature `STATE.md`; `aid-detail` → `task-NNN-STATE.md`; etc.). The result is **four different naming patterns** (skill-named SCREAMING-KEBAB, plain `STATE.md`, artifact-named, inline-only) and **three different inline-vs-separate dispositions** (both, inline-only, separate-only). A maintainer asking "where is `work-001` at?" must open and reconcile up to 6 files.

This feature consolidates state files into **one STATE.md per area**. AID has three areas, each with its own lifecycle:

- **Discovery** — persistent to the repo (Knowledge Base + visual summary). Lifecycle: build + validate the KB. One `.aid/knowledge/STATE.md`.
- **Work** — per work, repeats per delivery. Lifecycle: req → spec → plan → impl → deploy. One `.aid/work-NNN-{name}/STATE.md`.
- **Monitor** — per work, post-conclusion. Lifecycle: observe → classify → route. **Deferred** — the area is not mature; `MONITOR-STATE.md` per work follows the same area-state pattern when authored.

Artifact files (REQUIREMENTS.md, SPEC.md, PLAN.md, task-NNN.md, KB docs) keep their inline `## Change Log` sections — that's content history, distinct from process state. The artifact content schemas are unchanged.

## User Stories

- As a maintainer asking "where is work-001 at?", I want to open exactly one file and see the work's full lifecycle status, not hunt across 6+ scattered state files.
- As the traceability heartbeat (FR1), I want a single trace destination per area so the "you are here" answer doesn't fragment across files.
- As a reviewer triaging open questions across a work, I want all pending Q&A entries (from cross-reference, from `/aid-specify` loopback, from per-task review) consolidated in one section of one file.
- As an AID author updating a STATE file shape, I want one template per area to maintain, not six (one per skill).

## Priority

Should — supports FR1 traceability. Pain-point #4 (no progress visibility) is the user-perceived driver; FR2 is the structural reform that makes FR1's trace destination unambiguous.

## Acceptance Criteria

- [ ] **AC1 — Discovery-area STATE.** `.aid/knowledge/STATE.md` exists, consolidating the previous `DISCOVERY-STATE.md` and `SUMMARY-STATE.md`. Sections: KB Documents Status (the 16 docs × status × grade × last-reviewed × notes), Knowledge Summary Status (profile, machine grade, human grade, approval, last-run), Q&A (pending cross-skill questions about KB facts), Review History (per `/aid-discover` cycle), Summarization History (per `/aid-summarize` run). The deprecated files no longer exist.
- [ ] **AC2 — Work-area STATE.** Each work folder contains `.aid/work-NNN-{name}/STATE.md` with sections: Interview Status, Features Status (per-feature × spec status × grade × Q&A count), Plan / Deliveries, Tasks Status (per-task × status × type × wave × dependencies-met × review outcome × elapsed), Deploy Status (per-delivery × PR url × KB updated × tag), Cross-phase Q&A (pending), Lifecycle History (phase transitions, gate approvals). The deprecated files (`INTERVIEW-STATE.md`, per-feature `STATE.md`, `task-NNN-STATE.md`, `DEPLOYMENT-STATE.md`) no longer exist in any work folder.
- [ ] **AC3 — Artifact content unchanged.** REQUIREMENTS.md, SPEC.md, PLAN.md, task-NNN.md, and KB docs retain their inline `## Change Log` sections; their body schemas are unchanged. Only state-file shape moves.
- [ ] **AC4 — Templates updated.** `canonical/templates/` ships `work-state-template.md` and `discovery-state-template.md`. The retired templates (`interview-state.md`, `feature-state.md`, `implementation-state.md`, `deployment-state.md`, the old `discovery-state.md`, the `discovery-state-template.md` reviewer variant, anything `summary-state`-shaped) are removed (or kept only as deprecated tombstones pointing at the new templates).
- [ ] **AC5 — Dogfood works migrated.** `.aid/work-001-aid-lite/`, `.aid/work-002-canonical-generator/`, `.aid/work-003-traceability/` each have a single `STATE.md` in the new shape; their previous per-skill / per-feature / per-task state files are deleted.
- [ ] **AC6 — KB docs document the new rule.** `.aid/knowledge/data-model.md` enumerates the area STATE files and drops entries for the retired files. `.aid/knowledge/coding-standards.md` includes the area-STATE naming convention in its file-naming section.
- [ ] **AC7 — Monitor area noted as deferred.** REQUIREMENTS.md §5 and data-model.md both mark Monitor as deferred with a note that `MONITOR-STATE.md` follows the same area-state pattern when the Monitor area matures.

---

## Technical Specification

### Data Model

#### Discovery STATE schema (`.aid/knowledge/STATE.md`)

```
# Discovery State

**Status:** Approved | In Progress | Initial
**Minimum Grade:** A · **Current Grade:** {grade} · **User Approved:** yes/no
**Last KB Review:** YYYY-MM-DD · **Last Summary:** YYYY-MM-DD

## KB Documents Status
| # | Document | Status | Grade | Last Reviewed | Notes |
|---|---|---|---|---|---|
| 1 | project-structure.md | Populated | A | 2026-05-21 | … |
| ... 16 rows ... |

## Knowledge Summary Status
| Field | Value |
|---|---|
| Profile | auto-detected: web-app |
| Machine Grade | A |
| Human Grade | A |
| User Approved | yes (2026-05-21) |
| Last Run | 2026-05-22 |
| Output | knowledge-summary.html (3.2 MB) |
| Mermaid Version | 11.4.1 |

## Q&A (Pending)
### Q{N}: [{Category}: {Impact}]
… (cross-skill questions about KB facts)

## Review History
| # | Date | Grade | Source | Notes |

## Summarization History
| # | Date | Grade | Profile | Mermaid | Output | Notes |
```

#### Work STATE schema (`.aid/work-NNN-{name}/STATE.md`)

```
# Work State — work-NNN-{name}

**Status:** Interview Complete | Specifying | Planning | Detailing | Executing | Deployed
**Phase:** Interview | Specify | Plan | Detail | Execute | Deploy
**Minimum Grade:** A · **Started:** YYYY-MM-DD · **User Approved:** yes/no

## Interview Status
**Status:** {Interview status} · **Grade:** {grade}
| Section | Status | Last Updated |
| ... 10 rows ... |

## Features Status
| # | Feature | Spec Status | Spec Grade | Q&A Count | Notes |
| 001 | feature-001-… | Ready | A | 0 | … |

## Plan / Deliveries
| Delivery | Status | Tasks | Notes |
| delivery-001 | Approved | 30 | … |

## Tasks Status
| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
| 001 | task-001-… | IMPLEMENT | W1 | Done | A | 4m 12s | — |

## Deploy Status
| Delivery | State | PR | KB Updated | Tag | Notes |

## Cross-phase Q&A (Pending)
### Q{N}: [{Phase}: {Category}: {Impact}]
… (consolidated open questions across all phases)

## Lifecycle History
| Date | Phase Transition / Gate | Grade | Notes |
| 2026-05-23 | Interview → Specify | A | All features identified |
```

The `## Tasks Status` table is the iteration source for FR1's AC4 sub-unit drill-down on `aid-execute/EXECUTE-WAVE`.

### State Machines

This feature has a **one-time migration state machine** (per dogfood work being migrated):

```
PRE-MIGRATION
  └─→ CONSOLIDATE: read all source state files, build the new STATE.md
       └─→ DELETE-SOURCES: remove the now-orphan source files
            └─→ VERIFY: STATE.md present + sources gone + git status clean
                 └─→ DONE
```

Steady-state has no new state machines — STATE.md is just appended to / updated by the same skills that already write state, but to a different file.

### Feature Flow

#### Flow A — Discovery STATE writes (steady-state)

```
aid-init / aid-discover / aid-summarize  finishes a phase
        │
        ▼
[append to .aid/knowledge/STATE.md under the appropriate section]
        │  KB document updated → KB Documents Status row updated
        │  Review cycle finishes → Review History row appended
        │  Summary regenerated → Summarization History row appended
        │  Q&A raised → Q&A (Pending) entry added
        ▼
single file, single source of truth for Discovery
```

#### Flow B — Work STATE writes (steady-state)

```
aid-interview / aid-specify / aid-plan / aid-detail / aid-execute / aid-deploy  finishes a step
        │
        ▼
[append to .aid/work-NNN/STATE.md under the appropriate section]
        │  Interview section approved → Interview Status table updated
        │  Feature spec written → Features Status row updated
        │  Task completes → Tasks Status row updated (status, elapsed, review outcome)
        │  Delivery deploys → Deploy Status row updated
        │  Cross-phase Q&A raised → Cross-phase Q&A (Pending) entry added
        │  Phase transition → Lifecycle History row appended
        ▼
single file, single source of truth for Work
```

#### Flow C — One-time migration (per dogfood work + Discovery area)

```
For each migration target (work-001, work-002, work-003, knowledge):
        │
        ▼
[read all source state files]
        │  e.g. for work-001: INTERVIEW-STATE.md, features/*/STATE.md × 4
        │  build a single STATE.md following the area schema
        ▼
[write new STATE.md]
        │  binary-mode write to preserve LF endings
        ▼
[delete source files]
        │  git rm for tracked sources
        ▼
[verify]
        │  git status: M target + D sources, nothing else unexpected
        ▼
done
```

### Layers & Components

| Layer | Component | Role |
|-------|-----------|------|
| Canonical templates | `canonical/templates/work-state-template.md`, `canonical/templates/discovery-state-template.md` | The two new area-STATE templates. Retire the per-artifact and per-skill state templates. Generated into each install tree via `/aid-generate`. |
| Skills (steady-state writers) | All AID skills that previously wrote state files | Updated to write to the new area STATE files. Implementation lands alongside `work-001/feature-002` (skill-footprint-refactor / thin-router), which edits the same SKILL.md files anyway. |
| Dogfood works | `.aid/work-001-aid-lite/`, `.aid/work-002-canonical-generator/`, `.aid/work-003-traceability/`, `.aid/knowledge/` | Migrated in-place by this feature as part of CW3–CW6. One-time conversion. |
| Knowledge Base docs | `.aid/knowledge/data-model.md`, `.aid/knowledge/coding-standards.md` | Updated to document the new area-STATE rule and naming convention. |

**Dependencies:**

- **Hard dependency on `work-002` (canonical generator)** — already shipped. The new templates ship via the same `canonical/` → install-tree pipeline.
- **Implementation coupling to `work-001/feature-002`** — the skill body updates that read/write the new STATE shape land naturally alongside the thin-router refactor. This feature's spec (the rule + the dogfood migration) lands in `work-003`; the SKILL body updates land in `work-001/feature-002`.
- **No runtime dependency** for end users; the rule changes how AID artifacts are organized, not what runtime tools are needed.

### Migration Plan

1. **Spec the rule first.** Land FR2 in REQUIREMENTS.md + this feature SPEC (CW1). Done in the same commit as this file's creation.
2. **Update canonical templates** (CW2). Add the two new area-STATE templates; mark retired templates as deprecated pointers (or delete outright — TBD by /aid-specify).
3. **Migrate the dogfood works** (CW3–CW5). One commit per work, in order: work-003 first (eat our own dogfood; smallest), then work-001 (4 features), then work-002 (1 feature + many tasks). Each migration: read source state files, build consolidated STATE.md, delete sources, verify.
4. **Consolidate Discovery area** (CW6). `.aid/knowledge/STATE.md` from `DISCOVERY-STATE.md` + `SUMMARY-STATE.md`. Single commit.
5. **Update KB docs** (CW7). `data-model.md` drops retired-file entries and adds area STATE entries. `coding-standards.md` documents the naming convention.
6. **Final verification** (CW8). `/aid-generate` runs clean (templates valid); grep finds no orphan references to the retired file names; push to `work-003` branch.

**No skill body changes in this work.** The SKILL.md files in `canonical/skills/aid-*/` still reference the old state file names. They get updated when `work-001/feature-002` (skill-footprint-refactor) ships — at which point the thin-router refactor naturally edits all 10 SKILL.md files and the state-file references update with them. Until then: the dogfood works have the new STATE shape but the SKILL.md files still describe the old shape. **Acceptable interim state** — the new shape is structural; skills can be updated to match in a later work without breaking the dogfood STATE files.

**Backward compatibility:** None needed. The state files are local to a project's `.aid/` and not consumed by external tools. Any project that has the OLD state files keeps working with the OLD skills (which still know how to read them). After the SKILL update lands, projects can migrate at their convenience using the migration script (deferred to `aid-specify` to write).

### Open Questions

Genuine decision points — surfaced, not assumed.

*(none open — all three original OQs RESOLVED on 2026-05-23; see Resolved Questions below.)*

### Resolved Questions

#### OQ-1 — Concurrent-write design for Work STATE.md during parallel-task execution — **RESOLVED: Single-writer orchestrator**

When `work-001/feature-009` (parallel execution) is shipped, multiple in-flight tasks in the same wave may simultaneously want to update the Work STATE.md `## Tasks Status` table.

**Decision: single-writer orchestrator.** Only the orchestrating skill (`aid-execute`) writes STATE.md. Parallel sub-agents (developer / reviewer) return results to the orchestrator; the orchestrator serially appends updates to the `## Tasks Status` table (and to `## Lifecycle History` on phase transitions) as each result arrives.

**Reasoning:**

1. **Matches AID's existing architecture.** `aid-execute` already operates as the orchestrator-worker pattern (architecture.md §4 pattern #2). It dispatches sub-agents and collects results — extending that to "and serially appends to STATE.md on each result arrival" is the natural fit, not a new mechanism.
2. **No locking, no event sourcing.** File-lock requires cross-platform reconciliation (Windows vs POSIX semantics differ). Event-append needs a reader to reconstruct current status, adding complexity.
3. **Predictable ordering.** Status rows appear in the order results arrive, not in race-condition order — deterministic for human readers.
4. **Zero new dependency.** The orchestrator already has per-task results in hand; the write is an extra side-effect on each arrival.

**Rejected alternatives:** per-task event append (event-sourcing-style — reader complexity outweighs the writer simplicity benefit); file-lock with retry (cross-platform locking is fiddly).

**Implementation:** lands in `work-001/feature-009` (parallel-task execution) when that feature is implemented. Feature-002 (this SPEC) commits to the architectural decision; feature-009's SPEC will commit to the exact mechanism (e.g., a single `append-task-status` helper call in `aid-execute`'s wave-completion loop).

#### OQ-2 — Retire vs deprecate the old templates — **RESOLVED: Delete outright**

`canonical/templates/{interview-state, feature-state, implementation-state, deployment-state, discovery-state}.md` + `canonical/templates/reports/discovery-state-template.md`, plus the 12 phantom install-tree-only templates (`{interview, feature, discovery}-state.md` × 4 install locations).

**Decision: delete outright.** No tombstone stubs.

**Reasoning:**

- **Tombstones in install trees ship as noise to end-user projects.** A project installing AID via `setup.sh` would receive `.claude/templates/interview-state.md` containing "DEPRECATED — see work-state-template.md" — unhelpful clutter the end user never asked for.
- **No external consumers.** AID's state-file templates are internal to the methodology; no external tooling reads them. Breakage risk is zero.
- **History preserved by git.** Anyone tracing the evolution of state files via git log/blame can see the migration commits (CW1–CW7 on the `work-003` branch).

**Status:** Already executed in CW2 (commit `e363348`) as a forced pragmatic choice — the SPEC was being committed alongside the template deletions; deferring to a later /aid-specify pass wasn't feasible. This resolution formalizes that choice; no further file changes needed.

#### OQ-3 — Should Monitor get a stub `MONITOR-STATE.md` template now, or wait? — **RESOLVED: Wait until Monitor area matures**

**Decision: wait.** Do not author `canonical/templates/monitor-state-template.md` as part of work-003.

**Reasoning:**

- **Premature-design risk.** Monitor's lifecycle (observe → classify → route) isn't well-defined yet. A template authored now would crystallize assumptions that might not match the eventual Monitor design.
- **Not blocking.** H7 (the MONITOR-STATE template missing) is a documented tech-debt item; no project actively runs `aid-monitor` end-to-end today, so the absence doesn't block any active workflow.
- **The pattern is documented.** When Monitor matures and someone authors the template, the area-STATE rule (in REQUIREMENTS.md FR2 + data-model.md §1A + coding-standards.md §8.5) tells them exactly what shape to follow — no design context will be lost by waiting.
- **Uniform-templates-now is a weak win.** Two existing templates (`work-state-template.md`, `discovery-state-template.md`) already demonstrate the pattern; a third stub adds little.

**Trigger for revisiting:** when `aid-monitor` ships in production for any project (including AID's own dogfooding of itself), revisit OQ-3 and author the template. Until then, H7 stays open in tech-debt.md and Monitor-area work routes to the dedicated future work that matures the area.

---

## Notes

---

## Notes

- This feature does **not** have its own per-feature `STATE.md`. Per the new rule it codifies, the feature's status lives in `.aid/work-003-traceability/STATE.md` (created by CW3 in this very feature's migration plan).
- Once CW3 runs, `feature-001` also loses its per-feature STATE.md (absorbed into the same `STATE.md`). Both features in work-003 follow the new rule from that point forward.
