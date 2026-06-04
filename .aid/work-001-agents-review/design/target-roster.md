# Target Roster Spec — Derived Roster + Format/Generation Decision (FR3)

> Artifact (c) per `feature-001-roster-design/SPEC.md` §Deliverable Artifacts & Formats (c).
> Derived by intersecting the demand side (`design/needs-matrix.md`, 69 needs rows / 12 consumers)
> with the supply side (`design/current-audit.md`, 22 existing agents) under the ranked design
> principles (REQUIREMENTS.md §6): **(1) single-responsibility**, **(2) reuse**, **(3) authoring-
> simplicity**, applying derivation rules **R1–R5** (feature-001 SPEC §Roster-derivation criteria).
>
> **"Fewer agents" is an OUTCOME, not a target (R5 count-neutrality).** No rule below targets a
> specific final count. The resulting count (see *Outcome* note) is whatever R1–R4 produce.
>
> **Binding constraint carried from `architecture.md` §3:** the *reviewer-tier-≥-executor invariant*
> — a reviewer agent's tier must be ≥ the executor's so the writer never grades its own work. This
> constrains tier assignment for any agent used in REVIEW states, and is a reason a generalist
> reviewer role is kept distinct from the generalist executor/designer roles (see roster R1 notes).
>
> **`aid-` naming constraint (REQUIREMENTS.md §7, added 2026-06-04):** every roster name below carries
> the `aid-` prefix (e.g. `aid-architect`, `aid-reviewer`, `aid-clerk`). Rationale: AID installs
> agents into the user's host tool (e.g. `.claude/agents/`); unprefixed generic names (`reviewer`,
> `developer`, …) would collide with and overwrite the user's own agents — the `aid-` namespace prevents
> this. The prefix is a NAMING constraint only: it does not change the roster's composition (still 9
> roles, same merges), only the names. Consequence: because even the formerly-"keep" agents change name,
> the migration map (`migration-map.md`) has NO `keep` rows — the 8 namesakes are `rename`, their
> absorbers `merge`; FR6 therefore rewrites EVERY agent-name dispatch site and FR9 must confirm no bare
> (unprefixed) old name survives anywhere.

---

## Roster table

> One row per `proposed_agent`. `covers_needs` cites `needs-matrix.md` row numbers (the `#` column).
> Every row's `covers_needs` is non-empty (R4). Pairwise `single_responsibility` is non-overlapping (R1).
> `derivation_rationale` records which rule(s) fired and which old agents the role absorbs.

| proposed_agent | single_responsibility | covers_needs (needs-matrix rows) | consumers (skills that dispatch) | proposed_tier (+ rationale) | derivation_rationale (rule fired) |
|---|---|---|---|---|---|
| `aid-interviewer` | Conduct one-question-at-a-time adaptive stakeholder dialogue, capturing answers into requirements/intake/Q&A docs | 9, 10, 11, 12, 16, 17, 19(partial: gap-surfacing during requirements) | aid-interview | **large** — open-ended multi-turn elicitation against KB/codebase; FIRST-RUN/COMPLETION/CONTINUE are tagged large in needs-matrix; conversational reasoning is the costliest mode | **R2 keep** (dispatch_breadth 1 but distinct conversational modality that cannot fold into any other role without violating R1 — audit row marks "unique conversational modality, no meaningful overlap"). **R1**: no other roster row owns stakeholder dialogue. |
| `aid-architect` | Transform requirements/SPEC/PLAN into design output: SPEC sections, typed dependency-ordered task breakdowns, feature decomposition, delivery sequencing, and DESIGN-typed task execution (incl. UX/flow advice) | 3, 13, 18, 21, 22, 27, 30, 33(DESIGN-typed only), 51 | aid-detail, aid-discover, aid-execute, aid-housekeep, aid-interview, aid-plan, aid-specify | **large** — design/decomposition reasoning over KB+requirements; every covered need is tagged large | **R2 keep** (dispatch_breadth 6 — high reuse). **R1**: absorbs the design half of the architect/discovery-architect overlap; `discovery-architect` (read-only KB cataloguing) folds into `researcher`, not here, so the two non-overlapping responsibilities (propose design vs. catalogue existing) split cleanly. Also absorbs `ux-designer`: it has NO distinct need row (the only EXECUTE need is row 33; UX is the DESIGN-typed slice) and the audit flags it as advisory-only to architect → R1 strict-subset merge. Owns aid-discover GENERATE *orchestration* (need 3). |
| `aid-developer` | Implement, modify, refactor, and build-verify code from task files; raise IMPEDIMENT.md when spec contradicts reality | 33 (IMPLEMENT/TEST/REFACTOR/CONFIGURE/MIGRATE/DOCUMENT*), 35 (FIX), 6(partial: regenerate generated files during KB FIX) | aid-execute, aid-discover | **medium** — implementation per existing tier; matches audit `developer` tier=medium | **R1 merge** — absorbs `data-engineer` (MIGRATE) and `devops`-as-CONFIGURE-executor: audit flags both as strict subsets / per-type alternatives of developer in the aid-execute Agent Selection table. Task-type routing (the existing Agent Selection table) selects the executor; the *role* is one. **R3**: the per-type alternatives differ from developer mainly by domain framing, not by a distinct authoring body. (*DOCUMENT routes to `tech-writer`; see that row.) |
| `aid-researcher` | Read and analyze code/docs/logs/APIs and produce structured Knowledge Base / analysis documents (existing-state cataloguing, dependency/integration/convention mapping, telemetry interpretation, classification) | 3(per-doc population), 6, 33(RESEARCH-typed), 46, 47 | aid-discover, aid-execute, aid-monitor | **large** — needs 46/47 (OBSERVE/CLASSIFY) and the discovery-doc population are tagged large; deep code+telemetry analysis is large-tier work | **R1 merge** — absorbs the 5 read→KB discovery agents (`discovery-analyst`, `discovery-architect` [cataloguing half], `discovery-integrator`, `discovery-quality`, `discovery-scout`) plus the *analysis* surfaces of `performance` and `security`. Audit: all five discovery-* are "the generalist `researcher` scoped to specific KB docs + aid-discover only." The KB doc-set assignment is a *dispatch parameter* (which docs to populate), not a separate agent (R3). **R2**: each discovery-* is dispatch_breadth 1. |
| `aid-reviewer` | Adversarially review any artifact (code, tasks, specs, plans, KB docs) against its acceptance criteria / rubric / KB conventions; emit the 7-column issue ledger with source+severity tags | 4, 14, 19, 25, 28, 31, 34, 38 | aid-deploy, aid-detail, aid-discover, aid-execute, aid-interview, aid-plan, aid-specify | **large** — must satisfy the reviewer-tier-≥-executor invariant (`architecture.md` §3); the highest executor it grades is large, so reviewer is large | **R1 merge** — absorbs `discovery-reviewer`: audit confirms "same adversarial review pattern, same structured-issue-ledger output, same independence rule; only the target artifact differs." Target artifact (KB doc vs. code/spec) is a dispatch parameter, not a separate agent (R3). **R2**: dispatch_breadth 6 (kept regardless). Resolves needs-matrix A5 (aid-detail REVIEW should dispatch reviewer, flagged for FR6). |
| `aid-operator` | Run final release verification, package artifacts, create PRs/release notes, manage releases, update KB on ship | 40, 41, 42, 43 | aid-deploy | **medium** — release orchestration per existing tier; matches audit tier=medium | **R2 keep** (dispatch_breadth 1) — distinct responsibility (shipping releases) that cannot fold into `developer` (build-verify is per-task, not release-gated) or `devops` (builds infra vs. ships) without violating R1. Audit: "operator ships; devops builds the infrastructure they use." |
| `aid-orchestrator` | Route pipeline findings to the next phase/skill, enforce human gates, dispatch with context, manage parallel execution | 48 | aid-monitor | **medium** — coordination/routing per existing tier | **R2 keep** (dispatch_breadth 1 as an *agent*) — unique pipeline-coordination role with no content-production overlap (audit: in all other skills "the orchestrator" is the coordinating skill itself, not this agent). Folding into any content role would violate R1. |
| `aid-tech-writer` | Author user-facing documentation — API docs, changelogs, READMEs, release notes, user guides — and review docs for quality/accuracy | 33(DOCUMENT-typed), 6(partial: narrative KB docs), 43(partial: release notes) | aid-deploy, aid-discover, aid-execute | **medium** — documentation authoring per existing tier | **R2 keep** (dispatch_breadth 3) — cleanly delineated from `researcher` at the doc-type boundary (audit: tech-writer = user-facing docs; researcher = KB/analysis docs; both AGENT.md `What You Don't Do` blocks delineate). Distinct responsibility → R1 keep. |
| `aid-clerk` | Perform one mechanical, schema-bounded operation per dispatch — file extraction, template placeholder-fill, or glob enumeration — returning a markdown table/file with path+line evidence | 3, 6, 33 (the "may delegate mechanical work to simple-extractor/glob/formatter" / "may use mechanical sub-agents for extraction/enumeration" delegations inside the discovery-GENERATE/FIX and EXECUTE needs) | aid-discover, aid-execute (delegated by the large-tier agent running those needs) | **small** — purely mechanical, no reasoning; matches the three small-tier audit rows | **R1 merge** — absorbs `simple-extractor` + `simple-formatter` + `simple-glob`. Audit: "same tier, same 2 dispatch sites (state-generate.md:226, state-execute.md); the operation (extract / format-fill / glob) is a dispatch parameter within one narrow utility category." **R3**: three near-identical small bodies → one parameterized utility (operation chosen by the caller's instruction). **R2**: all three dispatch_breadth 2, identical consumers. |

**Single-responsibility (R1 / AC2) pairwise check:** aid-interviewer (dialogue) · aid-architect (design/decompose) · aid-developer (implement code) · aid-researcher (read→KB analysis) · aid-reviewer (grade artifacts) · aid-operator (ship releases) · aid-orchestrator (route pipeline) · aid-tech-writer (user-facing docs) · aid-clerk (mechanical ops). No two share a responsibility:
- aid-architect vs aid-researcher: *propose new design* vs *catalogue existing state* (the audit's core architect/discovery-architect distinction, now split across these two roles).
- aid-developer vs aid-operator: *per-task implement + build-verify* vs *release-gated ship*.
- aid-developer vs devops(folded): devops's executor role is CONFIGURE-typed implementation → aid-developer; no devops row exists, so no overlap.
- aid-researcher vs aid-tech-writer: *KB/analysis docs* vs *user-facing docs* (doc-type boundary).
- aid-reviewer vs every executor: reviewer grades, never authors (independence rule + tier invariant).
- aid-clerk vs all: no reasoning, schema-bounded mechanical output only.

**AC2 covers_needs check:** every row cites ≥1 valid `needs-matrix.md` row (validated against the 69-row matrix, rows 1–69). No row is empty. Inline "DONE / halt-summary" needs (rows 8, 15, 20, 26, 29, 32, 36, 37, 44, 45, 49, 54, 58, 61, 64, 67, 68 and the other inline `→inline` states) are **deliberately NOT covered by any agent** — they are inline skill states with no subagent dispatch (needs-matrix marks them `→inline`). They are demand rows that the *skill itself* satisfies, not roster agents; this is not an R4 violation because R4 requires each *agent* to cite ≥1 need, not each *need* to map to an agent.

**Optional-specialist folds (R1, demand-side justification for task-005 migration map).** Four
existing agents — `ux-designer`, `security`, `performance`, `devops` — have **no distinct need row** in
`needs-matrix.md`. The matrix has exactly one EXECUTE need (row 33), which routes by task type, and one
deploy need set (rows 40–43); these four agents appear in the current code only as *optional specialist
consults* layered onto those same needs (audit `dispatched_by`: ux-designer/security/performance/devops
are "optional specialist" / per-type-alternative rows, never a sole owner of a need). Under R1 each is a
strict subset of a generalist and folds without leaving a need uncovered:
- `ux-designer` → **aid-architect** (DESIGN-typed slice of need 33; advisory-to-architect per audit).
- `security` → **aid-researcher** for security-pattern *analysis*; the executor side (fix auth/PII) is
  `aid-developer` per its own `What You Don't Do` ("fix vulnerabilities — that's the Developer").
- `performance` → **aid-researcher** for profiling/analysis; the fix side is `aid-developer` (audit: "fix
  performance issues — that's the Developer").
- `devops` → **aid-developer** for CONFIGURE-typed execution (need 33) and **aid-operator** for the deploy
  consult (rows 40–43, which `aid-operator` already owns; audit: "devops builds infra, operator ships").

These folds are R1 (single-responsibility subset), reinforced by R5 (no count target). If feature-002
review finds a genuinely distinct, recurring need that none of the 9 generalists can serve without
violating R1, a specialist can be re-introduced — the roster is a hypothesis, and the migration map
(task-005) records these as `merge` dispositions so the decision is reversible and auditable.

**Outcome (count is emergent, not targeted — R5):** applying R1–R4 yields **9 proposed agents**, all `aid-`prefixed per REQUIREMENTS.md §7 (aid-interviewer, aid-architect, aid-developer, aid-researcher, aid-reviewer, aid-operator, aid-orchestrator, aid-tech-writer, aid-clerk), down from **22**. The reduction is the *result* of merging strict-subset/duplicate responsibilities and parameterizable utilities; no rule above set out to reach 9 or any other number. The `aid-` prefix is a collision-avoidance naming constraint applied to the emergent roster — it does not change the count or composition.

---

## Format decision

**Chosen option: (2) Shared-include for boilerplate** — keep one per-agent canonical source file
per agent, but factor the two duplicated blocks (`## Heartbeat protocol`, `## Self-review
discipline`) out of every `AGENT.md` and inject them at render time from the existing
`canonical/templates/{subagent-heartbeat-protocol,self-review-protocol}.md`.

> **`aid-` naming (REQUIREMENTS.md §7):** the per-agent canonical source dir is named with the
> prefix — `canonical/agents/<aid-name>/AGENT.md` (e.g. `canonical/agents/aid-reviewer/AGENT.md`) —
> and each agent's `name:` frontmatter is its `aid-`prefixed name. The chosen format does not change
> with the prefix; the prefix only fixes the dir name and the `name:` field.

### Why (against principle 3 + the buildable / 4-format render constraint, criteria i–iv)

- **(i) minimizes duplicated boilerplate (principle 3 — the primary criterion).** The audit
  (`current-audit.md` boilerplate truth) measured `## Heartbeat protocol` as a **byte-identical block
  in all 22** `AGENT.md` and `## Self-review discipline` in **19**. That is pure duplication: a wording
  change today requires editing up to 22 files. A shared include reduces each block to one canonical
  source, so authoring/maintaining an agent stops carrying that weight. This is the largest principle-3
  win available without redesigning the pipeline.
- **(ii) keeps each agent renderable into all 4 formats without new per-tool special-casing.** The
  include is resolved *before* the format branch runs (it operates on `body`, which every branch in
  `render_agents.py` consumes identically). markdown/toml/copilot-agent/antigravity-rule all receive
  the already-assembled body, so no branch needs to know about includes. Per-agent identity (name,
  description, tier, tools) is untouched, so `_render_codex_toml`'s one-file-per-agent requirement and
  the antigravity rule reshape both still work.
- **(iii) authoring a new agent stays a one-file, low-ceremony act.** The author writes only the
  role-specific sections (`What You Do` / `What You Don't Do` / role body) plus frontmatter; the two
  protocol blocks are no longer hand-copied. This is *strictly simpler* than status quo, not more
  ceremonious.
- **(iv) does not require redesigning the canonical→render→install pipeline (buildable constraint).**
  The canonical layout (`canonical/agents/<a>/AGENT.md`), the renderer entry points, and the 5-profile
  emission all stay. Only a render-time injection step is added (scoped to feature-002; see Generation
  decision for the exact mechanism, which is NOT the existing `substitute_filenames`).

### Alternatives compared (≥2, with trade-offs — DESIGN baseline)

| Option | Principle-3 effect | Buildable / 4-format effect | Verdict |
|---|---|---|---|
| **(1) Status quo** (boilerplate macro-copied into each AGENT.md, per `coding-standards.md §8e` items 3–4) | **Worst** — keeps 22× Heartbeat + 19× Self-review byte-identical duplication; a wording change is a 22-file edit (the FR2 concern). | Zero pipeline change; already builds. | **Rejected** — fails criterion (i), the primary principle-3 test. |
| **(2) Shared-include** (chosen) | **Best feasible** — both blocks reduced to one source each; authoring drops both blocks. | Render-time injection on `body` before the format branch; no per-tool special-casing; pipeline shape unchanged. | **Chosen.** |
| **(3) Single-file-per-agent** (collapse `AGENT.md` + `README.md`) | Minor — removes the README duplication but leaves the Heartbeat/Self-review duplication entirely (the bigger burden). Orthogonal to (2). | The renderer only consumes `AGENT.md` (`agents_dir.glob("*/AGENT.md")`); README is human-facing and not rendered, so collapsing it is a docs-hygiene change, not a render change. | **Deferred, not chosen as the format answer** — addresses a smaller burden than (i) targets; can be done independently in feature-002 if desired, but it is not the boilerplate fix. |
| **(4) Consolidated manifest** (one source listing all agents) | Best on paper for shared sections. | **Highest risk to (ii)/(iv)** — `render_agents.py` iterates per-`AGENT.md` and emits per-agent output (`_render_codex_toml` one `.toml` per agent; antigravity one rule file per agent). A manifest forces a parser rewrite + per-agent splitting in every branch — a pipeline redesign. | **Rejected** — violates criterion (iv) (buildable without redesign) and risks (ii). |

**Conclusion:** (2) is the only option that maximizes the principle-3 win (i) while satisfying (ii),
(iii), and (iv). (3) is a complementary, smaller, optional cleanup; (1) and (4) fail a criterion.

---

## Generation decision

**Decision: `render_agents.py` and `profiles/*.toml` DO need a change to emit the chosen
shared-include format — a small, additive one — and the change belongs to feature-002 (FR5/FR7),
not here.**

> **`aid-` naming pass-through (REQUIREMENTS.md §7):** no renderer change is needed for the prefix
> itself — the renderer already derives every emitted name and filename from the per-agent source
> dir / `name:` frontmatter (`render_agents()` globs `canonical/agents/*/AGENT.md`). Once the
> canonical dirs are `canonical/agents/aid-<role>/` with `name: aid-<role>`, every output branch
> emits the `aid-`prefixed name and filename automatically: markdown `aid-<role>.md` (claude-code,
> cursor), Codex `aid-<role>.toml`, Copilot `aid-<role>.agent.md`, Antigravity
> `.agent/rules/aid-<role>.md`. So the install trees write `.claude/agents/aid-reviewer.md` (etc.),
> which is exactly the collision-avoidance the §7 constraint requires. Feature-002 must confirm the
> four format branches and the determinism gate stay green with the prefixed names.

### What the renderer does today (grounded in the 4 per-format branches)

`render_agents.py` `_render_agent_for_profile` reads each `canonical/agents/<a>/AGENT.md`, parses
frontmatter, applies `substitute_filenames(body, …)` then `rewrite_install_paths(body, …)`, then
dispatches on `profile.agent.format` into exactly four branches:
- `"toml"` → `_render_codex_toml` (Codex; one `.toml` per agent, body as `developer_instructions`).
- `"copilot-agent"` → `_build_frontmatter_md_copilot` + body (Copilot CLI; `.agent.md`).
- `"antigravity-rule"` → `_build_frontmatter_md_antigravity` + body (Antigravity; `.agent/rules/<name>.md`).
- else markdown → `_build_frontmatter_md` + body (Claude Code, Cursor; `.md`).

All four consume the same already-transformed `body`. The `profiles/*.toml` `[agent].format` values
are `markdown` (claude-code, cursor), `toml` (codex), `copilot-agent` (copilot-cli), `antigravity-rule`
(antigravity).

### Why a change is needed (do NOT assume the existing machinery does it)

The feature-001 SPEC §Format-criteria option-2 text suggested the shared-include "leverages the
existing renderer substitution machinery (`substitute_filenames`)." **That is not accurate and
feature-002 must not rely on it.** `substitute_filenames` (`render_lib.py:88`) only replaces three
fixed placeholder keys — `{project_context_file}`, `{reviewer_output_file}`, `{open_questions_file}`
— and silently leaves every other `{...}` token untouched. It cannot inject an arbitrary include file.

So feature-002 needs a **new, additive render step**: an include-resolution pass that runs on `body`
**before** the format-branch dispatch (e.g. a placeholder like `{{include:subagent-heartbeat-protocol}}`
resolved against `canonical/templates/…`, or appending the two blocks unconditionally where the agent
opts in). Because it runs before the branch, all four format branches keep working unchanged — that is
the property that satisfies format-criterion (ii). The change is:
- **`render_agents.py`:** add one include-resolution call in `_render_agent_for_profile` before the
  `if profile.agent.format == …` dispatch (analogous to where `substitute_filenames`/
  `rewrite_install_paths` already run on `body`). No format branch changes.
- **`profiles/*.toml`:** **no change required** if the include is unconditional/source-driven (the
  agent files declare the include). A profile flag is optional, not necessary.
- **Determinism (`--self-test` hard gate):** the include pass must be deterministic (read same source,
  same order) so the byte-identical re-render audit still passes; this is a feature-002 AC4/`/aid-generate`
  clean-run concern, flagged here as a constraint, not implemented here.

### Stale `aid-generate` references — flagged as input to feature-002 FR7

`.claude/skills/aid-generate/SKILL.md` still describes **"three install trees (claude-code, codex,
cursor)"** and a **`--tool claude-code|codex|cursor`** enum (lines 4, 8, 15, 19, 61, 135, 256) — these
lag the **five** profiles now present (`claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`).
The needs-matrix even records the VALIDATE mode as still expecting "22 agents present" (row 66), which
the roster reduction to 9 will also invalidate. **These are inputs to feature-002 FR7**, which must:
- update the "three trees" / `--tool` enum to the five profiles;
- update the VALIDATE expected-agent count from 22 to the approved roster count (9);
- wire in the new include-resolution step's verification.

This feature does **not** edit `aid-generate`, run the generator, or touch `render_agents.py` /
`profiles/*.toml` — it only records the required change and its shape for feature-002.

---

## Self-consistency / AC summary

- **AC2 (covers_needs non-empty + references valid needs-matrix rows):** PASS — all 9 rows cite ≥1
  row from the 69-row matrix; cited row numbers verified in range 1–69.
- **AC2 (pairwise single_responsibility, no overlap — R1):** PASS — see the pairwise check above; the
  architect/researcher, developer/operator, researcher/tech-writer boundaries are the load-bearing
  splits and each is non-overlapping.
- **Each disposition records the firing rule (R1–R5):** PASS — every roster row's
  `derivation_rationale` names R1/R2/R3 (and R4 via the covers_needs guard); no rule targeted a count.
- **R5 count-neutrality:** PASS — 9 is stated as an emergent OUTCOME of R1–R4, not a goal.
- **Format AC:** PASS — option (2) shared-include named and justified vs principle 3 + the buildable/
  4-format constraint (criteria i–iv); ≥2 alternatives compared with trade-offs.
- **Generation AC:** PASS — states render_agents.py needs one additive include step (and corrects the
  SPEC's inaccurate `substitute_filenames` assumption), profiles need no required change, and flags the
  `aid-generate` stale "three trees"/`--tool`/22-count refs as feature-002 FR7 inputs.
- **Write boundary:** only this file was written; no agent/skill/profile/KB mutation; generator not run.
