# Migration Map — Old→New Disposition Contract (FR4)

> Artifact (d) per `feature-001-roster-design/SPEC.md` §Deliverable Artifacts & Formats (d) and
> §Migration Plan considerations. The deterministic input contract handed to
> **feature-002-roster-rollout** (FR6 rewire / FR9 consistency check).
>
> **Exactly 22 rows** — one per directory under `canonical/agents/` (set-equality with the audit's
> 22 supply rows, both directions empty-diff). Each row carries a closed-enum `disposition`
> (`keep | merge | rename | drop`), a `new_agent` destination (EMPTY only for `drop`), a one-line
> `rationale` tied to the firing rule/principle, and a `dispatch_rewrite_hint` naming the CLASS of
> dispatch sites feature-002 must rewire — referencing the measured `dispatch_breadth` /
> `dispatched_by` from `current-audit.md`.
>
> **Source of every disposition:** the absorption statements in `design/target-roster.md` (task-003).
> No new roster decision is introduced here; this map only records, per old agent, the destination
> task-003 already assigned. Ranked principles: (1) single-responsibility / R1, (2) reuse / R2,
> (3) authoring-simplicity / R3, R5 count-neutrality.
>
> **`aid-` naming constraint (REQUIREMENTS.md §7, added 2026-06-04):** every final-roster agent
> carries an `aid-` prefix (collision-avoidance — installing AID must never overwrite a user's own
> `.claude/agents/<name>.md`). Because even the formerly-"keep" agents now change name, **there are
> NO `keep` rows left** — all 22 old bare names disappear, replaced by 9 `aid-*` targets.
>
> **Disposition scheme (uniform):** for each destination, the **namesake** old agent (the bare-name
> agent the prefixed target derives from, e.g. `architect`→`aid-architect`) is marked **`rename`**
> (its only change is the prefix); every **absorbed** old agent (a strict-subset/duplicate folded in,
> e.g. `ux-designer`→`aid-architect`) is marked **`merge`**. The one destination with no namesake
> among the 22 — `aid-clerk` (the parameterized fold of the three `simple-*` utilities) —
> has all three of its olds marked `merge`. This scheme is applied uniformly to every row.
>
> **Closure invariant (verified below):** `{ non-blank new_agent } == { the 9 `aid-*` proposed-roster
> agents }`, empty-diff both directions; every roster agent reachable from ≥1 old agent; no drops, so
> no roster agent depends on a dropped agent.

| old_agent | disposition | new_agent | rationale | dispatch_rewrite_hint |
|---|---|---|---|---|
| `architect` | rename | `aid-architect` | Namesake of `aid-architect` (only change = `aid-` prefix per §7). R2 (dispatch_breadth 6, high reuse); R1 owns the design/decompose half of the architect/discovery-architect split + absorbs ux-designer's DESIGN slice. | Word-boundary replace every bare `architect` dispatch site → `aid-architect`. Sites: aid-detail/SKILL.md:72, aid-discover/SKILL.md:211–214, aid-housekeep/SKILL.md:219, aid-interview/SKILL.md:23,26,311,316, aid-plan/SKILL.md:129, aid-specify/SKILL.md:159–160 (6 SKILL.md dispatch-table rows). Feature-002 ALSO lands here: ux-designer→`aid-architect` DESIGN-typed sites (below) and the aid-detail REVIEW mis-route (→`aid-reviewer`, FR6). CLASS: SKILL.md dispatch-table rows naming `architect` + incoming ux-designer routes. |
| `data-engineer` | merge | `aid-developer` | R1 merge — strict subset of developer (data-layer only); MIGRATE is task-type routing, not a distinct role (audit: per-type alternative in aid-execute Agent Selection table). Folds into the `aid-developer` target. | Rewire the 2 dispatch sites (breadth 2): aid-detail/references/task-decomposition.md:12 (MIGRATE optional-consult row) + aid-execute/references/state-execute.md:29 (Worker MIGRATE row in Agent Selection table) → `aid-developer`. CLASS: `references/state-*.md` Agent-Selection / task-decomposition per-type rows. |
| `developer` | rename | `aid-developer` | Namesake of `aid-developer` (only change = `aid-` prefix per §7). R1 merge target — the single implement/build-verify executor; absorbs data-engineer, devops (CONFIGURE), and the executor/fix side of security & performance. tier medium per audit. | Word-boundary replace every bare `developer` dispatch site → `aid-developer`. Feature-002 also collapses the aid-execute Agent Selection table (state-execute.md:24–31) so MIGRATE/CONFIGURE/(IMPLEMENT-fix) all route to `aid-developer`; sites: aid-execute/references/state-execute.md:26–30 + SKILL.md frontmatter `agent: developer`. CLASS: SKILL.md/references rows naming `developer` + aid-execute Agent-Selection table consolidation. |
| `devops` | merge | `aid-developer` | R1 merge — devops's executor role is CONFIGURE-typed implementation → developer; the deploy consult (rows 40–43) is already owned by operator, so the destination is `aid-developer` (audit: "devops builds infra, operator ships"). | Rewire the 2 sites (breadth 2): aid-execute/references/state-execute.md:31 (Worker CONFIGURE row) → `aid-developer`; aid-deploy/SKILL.md:19 (optional CI/CD specialist consult) → drop/redirect to `aid-operator`'s release flow per FR6. CLASS: aid-execute Agent-Selection CONFIGURE row + aid-deploy SKILL.md optional-consult line. |
| `discovery-analyst` | merge | `aid-researcher` | R1 merge — "the generalist researcher scoped to specific KB docs + aid-discover only"; the doc-set (module-map/coding-standards/schemas) is a dispatch parameter, not a role (R3). dispatch_breadth 1. | Rewire the aid-discover dispatch CLASS (breadth 1): aid-discover/SKILL.md:219 (dispatch-table note naming the discovery-* parallel agents) + aid-discover/references/state-generate.md:220 (parallel Step 3/5 agent row) → `aid-researcher` (parameterized with this doc-set). CLASS: aid-discover SKILL.md dispatch table + state-generate.md parallel-agent rows. |
| `discovery-architect` | merge | `aid-researcher` | R1 merge — discovery-architect is read-only KB cataloguing (architecture.md/technology-stack.md) → researcher; the *propose-design* half (not this agent) is what `aid-architect` keeps, so this read-only agent folds to `aid-researcher` (target-roster architect/researcher split). | Rewire the aid-discover CLASS (breadth 1): aid-discover/SKILL.md:219 (dispatch-table note) + aid-discover/references/state-generate.md:219 (parallel Step 2/5 agent row) → `aid-researcher` (doc-set parameter). CLASS: aid-discover SKILL.md dispatch table + state-generate.md parallel-agent rows. |
| `discovery-integrator` | merge | `aid-researcher` | R1 merge — API/integration mapping (pipeline-contracts/integration-map/domain-glossary) is researcher's read→KB analysis scoped to 3 docs; doc-set is a dispatch parameter (R3). dispatch_breadth 1. | Rewire the aid-discover CLASS (breadth 1): aid-discover/SKILL.md:219 (dispatch-table note) + aid-discover/references/state-generate.md:221 (parallel Step 4/5 agent row) → `aid-researcher` (doc-set parameter). CLASS: aid-discover SKILL.md dispatch table + state-generate.md parallel-agent rows. |
| `discovery-quality` | merge | `aid-researcher` | R1 merge — tests/security/debt/infra assessment is read→KB analysis (test-landscape/tech-debt/infrastructure); folds into researcher with doc-set as a dispatch parameter (R3); absorbs the security/perf *analysis* overlap. dispatch_breadth 1. | Rewire the aid-discover CLASS (breadth 1): aid-discover/SKILL.md:219 (dispatch-table note) + aid-discover/references/state-generate.md:222 (parallel Step 5/5 agent row) → `aid-researcher` (doc-set parameter). CLASS: aid-discover SKILL.md dispatch table + state-generate.md parallel-agent rows. |
| `discovery-reviewer` | merge | `aid-reviewer` | R1 merge — same adversarial review pattern, same 7-column issue-ledger output, same independence rule; only the target artifact (KB doc vs code/spec) differs, which is a dispatch parameter (R3). | Rewire the aid-discover review CLASS (breadth 1): aid-discover/references/state-review.md:30 ("Dispatch the discovery-reviewer subagent") + the state-generate.md generate-phase review step → `aid-reviewer` (target-artifact parameter). CLASS: aid-discover state-review.md / state-generate.md review-step dispatch lines. |
| `discovery-scout` | merge | `aid-researcher` | R1 merge — structural/inventory read mapping (project-structure/external-sources) is researcher's read→analyze scope scoped to 2 docs; doc-set is a dispatch parameter (R3). dispatch_breadth 1. | Rewire the aid-discover pre-scan CLASS (breadth 1): aid-discover/references/state-generate.md:146–158 (Step 1 ALWAYS-first pre-scan agent) → `aid-researcher` (pre-scan/doc-set parameter). CLASS: aid-discover state-generate.md Step-1 pre-scan dispatch block. |
| `interviewer` | rename | `aid-interviewer` | Namesake of `aid-interviewer` (only change = `aid-` prefix per §7). R2 (dispatch_breadth 1) — unique conversational stakeholder-dialogue modality; no R1-safe fold into any other role (audit: "no meaningful overlap"). | Word-boundary replace every bare `interviewer` dispatch site → `aid-interviewer`. Sites: aid-interview/SKILL.md:307–315 (dispatch-table Worker rows for FIRST-RUN/Q-AND-A/TRIAGE/CONDENSED-INTAKE/CONTINUE/COMPLETION). CLASS: aid-interview SKILL.md dispatch-table Worker rows naming `interviewer`. |
| `operator` | rename | `aid-operator` | Namesake of `aid-operator` (only change = `aid-` prefix per §7). R2 (dispatch_breadth 1) — distinct release-gated ship responsibility; cannot fold into developer (per-task build-verify ≠ release gate) or devops without violating R1. | Word-boundary replace every bare `operator` dispatch site → `aid-operator`. Sites: aid-deploy/SKILL.md:18 (default executor) + aid-deploy/SKILL.md:124–127 (Worker IDLE/SELECTING/VERIFYING/PACKAGING). Feature-002 may redirect devops's aid-deploy optional CI/CD consult into this flow (see devops row). CLASS: aid-deploy SKILL.md default-executor + Worker rows naming `operator`. |
| `orchestrator` | rename | `aid-orchestrator` | Namesake of `aid-orchestrator` (only change = `aid-` prefix per §7). R2 (dispatch_breadth 1 as an agent) — unique pipeline-routing/gate-enforcement role with no content-production overlap; folding violates R1. | Word-boundary replace every bare `orchestrator` agent-dispatch site → `aid-orchestrator`. Sites: aid-monitor/SKILL.md:188 (Worker ROUTE) + aid-monitor/SKILL.md:19 (default executor). Note: "the orchestrator" PROSE in other skills = the coordinating skill, NOT an agent dispatch — do NOT rewrite those (the prose noun gets no `aid-` prefix). CLASS: aid-monitor SKILL.md agent-dispatch rows naming `orchestrator` (prose excluded). |
| `performance` | merge | `aid-researcher` | R1 merge — profiling/analysis is read→KB analysis → researcher; the FIX side is `aid-developer` per its own `What You Don't Do` ("fix performance issues — that's the Developer"), and the analysis fold lands the row destination on `aid-researcher` (target-roster optional-specialist fold). dispatch_breadth 1. | Rewire the 2 optional-consult sites (breadth 1, aid-execute): aid-execute/references/state-execute.md:26–27 (hot-path IMPLEMENT / load-test TEST optional specialist) → `aid-researcher` for analysis tasks / `aid-developer` for the fix-task type per FR6 routing; aid-execute/references/state-delivery-gate.md:109 (Specialist-consults count) update. CLASS: aid-execute state-execute.md optional-specialist consult rows + delivery-gate specialist count. |
| `researcher` | rename | `aid-researcher` | Namesake of `aid-researcher` (only change = `aid-` prefix per §7). R1 merge target — the generalist read→KB analysis role; absorbs all 5 discovery-* read agents + the analysis surfaces of security & performance. dispatch_breadth 3. | Word-boundary replace every bare `researcher` dispatch site → `aid-researcher`. Sites: aid-execute/references/state-execute.md:24 (Worker RESEARCH), aid-monitor/SKILL.md:186–187 (Worker OBSERVE+CLASSIFY), aid-discover/references/state-fix.md:27 (depth-investigation option). Feature-002 also routes the 6 incoming discovery/security/perf merges here via doc-set/target parameters. CLASS: SKILL.md/references rows naming `researcher` + receiver of the discovery-*/security/perf analysis rewires. |
| `reviewer` | rename | `aid-reviewer` | Namesake of `aid-reviewer` (only change = `aid-` prefix per §7). R2 (dispatch_breadth 6); R1 merge target — absorbs discovery-reviewer; satisfies the reviewer-tier-≥-executor invariant (architecture.md §3). tier large. | Word-boundary replace every bare `reviewer` dispatch site → `aid-reviewer`. Sites: aid-deploy/SKILL.md:19, aid-detail/references/first-run.md:70 + review.md:49, aid-execute/SKILL.md:140,144, aid-interview/SKILL.md:24,27,312,317, aid-plan/SKILL.md:130, aid-specify/SKILL.md:163 (6 SKILL.md + references dispatch rows). Feature-002 also fixes the aid-detail REVIEW mis-route (needs-matrix A5, →`aid-reviewer`) and lands the discovery-reviewer merge here. CLASS: SKILL.md/references rows naming `reviewer` + discovery-reviewer rewire + A5 fix. |
| `security` | merge | `aid-researcher` | R1 merge — security-pattern *analysis* is read→KB analysis → researcher; the executor/fix side is `aid-developer` per its own `What You Don't Do` ("fix vulnerabilities — that's the Developer"); the analysis fold sets the row destination to `aid-researcher` (target-roster optional-specialist fold). dispatch_breadth 2. | Rewire the 2 optional-consult sites (breadth 2): aid-detail/references/task-decomposition.md:12 (auth/PII task consult) + aid-execute/references/state-execute.md:26,31 (IMPLEMENT auth/PII, CONFIGURE secrets/auth optional specialist) → `aid-researcher` for analysis / `aid-developer` for fix-task type per FR6 routing. CLASS: aid-detail task-decomposition consult + aid-execute state-execute.md optional-specialist rows. |
| `simple-extractor` | merge | `aid-clerk` | R1/R3 merge — three near-identical small bodies → one parameterized utility; the operation (extract) is a caller-chosen dispatch parameter. dispatch_breadth 2. (`aid-clerk` is the one destination with NO namesake among the 22 — reached only by the three `simple-*` merges, so all three are `merge`.) | Rewire the 2 sites (breadth 2): aid-discover/references/state-generate.md:226 (mechanical-delegation prose naming simple-extractor) + aid-execute/references/state-execute.md:59 (`subagent_type: simple-extractor`) → `aid-clerk` with `operation: extract`. CLASS: state-generate.md delegation prose + state-execute.md subagent_type line. |
| `simple-formatter` | merge | `aid-clerk` | R1/R3 merge — template placeholder-fill is the same narrow utility category; operation is a dispatch parameter. dispatch_breadth 2. | Rewire the 2 sites (breadth 2): aid-discover/references/state-generate.md:226 (delegation prose naming simple-formatter) + aid-execute/references/state-execute.md (explicit dispatch) → `aid-clerk` with `operation: format`. CLASS: state-generate.md delegation prose + state-execute.md subagent dispatch. |
| `simple-glob` | merge | `aid-clerk` | R1/R3 merge — glob enumeration is the same narrow utility category; operation is a dispatch parameter. dispatch_breadth 2. | Rewire the 2 sites (breadth 2): aid-discover/references/state-generate.md:226 (delegation prose naming simple-glob) + aid-execute/references/state-execute.md (explicit dispatch) → `aid-clerk` with `operation: glob`. CLASS: state-generate.md delegation prose + state-execute.md subagent dispatch. |
| `tech-writer` | rename | `aid-tech-writer` | Namesake of `aid-tech-writer` (only change = `aid-` prefix per §7). R2 (dispatch_breadth 3) — distinct user-facing documentation role, delineated from researcher at the doc-type boundary (both `What You Don't Do` blocks). | Word-boundary replace every bare `tech-writer` dispatch site → `aid-tech-writer`. Sites: aid-execute/references/state-execute.md:28 (Worker DOCUMENT), aid-discover/references/state-fix.md:27 (narrative KB docs), aid-deploy/SKILL.md:19 (release-notes consult). CLASS: SKILL.md/references rows naming `tech-writer`. |
| `ux-designer` | merge | `aid-architect` | R1 merge — no distinct need row; the only EXECUTE need is the DESIGN-typed slice of need 33 and UX is advisory-to-architect (audit: "you advise; architect decides") → strict-subset fold into `aid-architect`. dispatch_breadth 2. | Rewire the 2 sites (breadth 2): aid-execute/references/state-execute.md:25 (Worker DESIGN row) + aid-detail/references/task-decomposition.md:12 (DESIGN-typed optional consult) → `aid-architect`. CLASS: aid-execute Agent-Selection DESIGN row + aid-detail task-decomposition consult. |

---

## Closure verification

**Disposition tally (22 rows) — `aid-` naming scheme: namesake = `rename`, absorbed = `merge`:**
- `keep` = 0. (The `aid-` prefix changes every name, so NO old bare name survives unchanged — there are no pure keeps.)
- `rename` = 8 — the 8 namesakes whose only change is the prefix: architect→aid-architect, developer→aid-developer, interviewer→aid-interviewer, operator→aid-operator, orchestrator→aid-orchestrator, researcher→aid-researcher, reviewer→aid-reviewer, tech-writer→aid-tech-writer.
- `merge` = 14 — data-engineer→aid-developer, devops→aid-developer, discovery-analyst→aid-researcher, discovery-architect→aid-researcher, discovery-integrator→aid-researcher, discovery-quality→aid-researcher, discovery-reviewer→aid-reviewer, discovery-scout→aid-researcher, performance→aid-researcher, security→aid-researcher, simple-extractor→aid-clerk, simple-formatter→aid-clerk, simple-glob→aid-clerk, ux-designer→aid-architect.
- `drop` = 0. (No drop rows → no roster agent depends on a dropped agent; the "no dependent" guard is vacuously satisfied.)
- Total = 0 + 8 + 14 + 0 = **22**. ✓
- Note: `aid-clerk` is the one destination with no namesake among the 22, so all three of its olds are `merge` (no `rename`); every other destination has exactly one `rename` namesake + zero-or-more `merge` absorbers.

**old_agent set == 22 `canonical/agents/` dirs (empty-diff both directions):** ✓
architect, data-engineer, developer, devops, discovery-analyst, discovery-architect, discovery-integrator,
discovery-quality, discovery-reviewer, discovery-scout, interviewer, operator, orchestrator, performance,
researcher, reviewer, security, simple-extractor, simple-formatter, simple-glob, tech-writer, ux-designer.

**Closure — `{ non-blank new_agent } == { 9 `aid-*` proposed-roster agents }`, empty-diff both directions:**

| roster agent (target-roster.md) | reachable from old agent(s) | in non-blank new_agent set? |
|---|---|---|
| `aid-interviewer` | interviewer (rename) | ✓ |
| `aid-architect` | architect (rename), ux-designer (merge) | ✓ |
| `aid-developer` | developer (rename), data-engineer, devops (merge) | ✓ |
| `aid-researcher` | researcher (rename), discovery-analyst/architect/integrator/quality/scout, security, performance (merge) | ✓ |
| `aid-reviewer` | reviewer (rename), discovery-reviewer (merge) | ✓ |
| `aid-operator` | operator (rename) | ✓ |
| `aid-orchestrator` | orchestrator (rename) | ✓ |
| `aid-tech-writer` | tech-writer (rename) | ✓ |
| `aid-clerk` | simple-extractor, simple-formatter, simple-glob (merge) | ✓ |

- non-blank `new_agent` set used in the table = {aid-architect, aid-developer, aid-researcher, aid-reviewer, aid-operator, aid-orchestrator, aid-interviewer, aid-tech-writer, aid-clerk} → exactly the 9 `aid-*` names. No extra destination, none missing. **Empty-diff both directions.** ✓
- Every one of the 9 roster agents is reachable from ≥1 old agent (column 2). Every `aid-*` target except `aid-clerk` has a namesake `rename` source; `aid-clerk` is reached by the 3 simple-* merges. No bare old name appears as a destination. ✓

**Every merge/rename names an exact new_agent; every drop has empty new_agent:** ✓ (all 8 renames + 14 merges name a destination; 0 drops; the only EMPTY-eligible disposition class is unused).

**Every row carries a dispatch_rewrite_hint naming the dispatch-site class(es) for FR6/FR9:** ✓
Because the `aid-` prefix rewrites EVERY old bare name (no pure keeps), every row's hint now names a
real rewire: the 8 `rename` rows say "word-boundary replace bare `<name>` → `aid-<name>`" at their
dispatch sites; the 14 `merge` rows name the file:line site class + measured breadth for folding the
old name into its `aid-` target. No row is a no-op.

**No new roster decision introduced:** every disposition's *destination roster role* is the one
already stated in `target-roster.md` (the 8 R2/R1-target rows are now `rename` to their `aid-`
namesake; merges = its absorption list incl. the optional-specialist fold block). The `aid-` prefix
is a NAMING change mandated by REQUIREMENTS.md §7, not a change to the roster's composition — same 9
roles, same merge groups. This map records, it does not decide.
