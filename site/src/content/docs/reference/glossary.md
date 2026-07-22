---
title: 'Glossary'
description: 'Definitions of AID concepts, phases, artifacts, and install terms.'
sourceDoc: 'docs/glossary.md'
---

Terms and concepts used throughout the AID methodology.

---

## Core Concepts

**AID (AI Integrated Development):** A structured methodology for building and maintaining software with AI agents. 6 numbered pipeline phases delivered by the curated classic pipeline / on-demand skills across 4 groups (Support, Knowledge Base Maintenance, Definition, Execution), plus a 94-row shortcut catalog — 64 shortcut skills (engine-generated verb-first doorways) plus 30 hand-authored `repurpose` skills — and the standalone `/aid-triage` router: 108 skills total (14 curated + 94 catalog). Delivery (Deploy, Monitor), the summary skill, and the on-demand Q&A/KB-update/connector skills are optional. Human and AI co-execute every phase.

**Knowledge Base (KB):** 14 standard markdown documents (plus 3 meta-documents: INDEX, README, STATE) that capture the living understanding of a project. The gravitational center of AID — not the spec, not the code. Updated continuously across phases. The default set of 14 is configurable via `discovery.doc_set` in `.aid/settings.yml`. Note: "3 meta-documents" is a *role* distinction (generated/process ledgers, review-exempt) — it is orthogonal to the *concern* axis. A standard document (among the 14) may carry an *orientation* concern (cross-cutting, not mapped to a single spine dimension); `external-sources.md` is exactly this: it is a standard, authored, review-eligible KB document whose concern is orientation — orientation on the concern axis does not make a document a meta-document on the role axis.

**Feedback Loop:** A formal pathway for a downstream phase to revise upstream artifacts. Produces a formal record (a Q&A entry in a STATE file, an IMPEDIMENT file, or an aid-monitor finding) with a revision trail.

**Phase Gate:** A human decision point between phases. The human reviews the phase output and approves advancement. "OK?" is the gate.

**Iron Man Model:** The human-AI collaboration philosophy. The AI is the suit (amplifies capability). The human is the pilot (sets direction, makes decisions). The human never leaves the cockpit.

---

## Setup

**aid-config:** Bootstrapping step that runs before the pipeline begins. Asks greenfield or brownfield, collects project metadata, and scaffolds the `.aid/knowledge/` directory with 14 empty KB document templates. Also creates `AGENTS.md`, `CLAUDE.md`, `README.md`, `INDEX.md`, and `STATE.md` placeholders. Not a methodology phase — it prepares the project so Discovery (or Describe) can begin cleanly.

---

## Phases

| Phase | Group | Produces |
|-------|-------|----------|
| **Discover** | Knowledge Base Maintenance | Knowledge Base (14 standard documents) |
| **Describe → Define** | Definition | Full path: `REQUIREMENTS.md` + per-feature `SPEC.md` stubs. Lite path (via a shortcut): work-root `SPEC.md` directly. |
| **Specify** | Definition | Technical specification added to each feature's `SPEC.md` (full path only) |
| **Plan** | Definition | `PLAN.md` (execution graph) + `deliveries/delivery-NNN/BLUEPRINT.md` (delivery definition) — full path only |
| **Detail** | Definition | `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` (task definition) — full path only |
| **Execute** | Execution | Reviewed, graded code (8 task types, built-in review loop) |

> *Deploy and Monitor are **optional**, on-demand delivery skills — separate, independently-invoked paths, not required, numbered phases (the numbered sequence ends at Execute). Run them when the project's delivery model calls for them; neither presupposes the other.*

---

## The Lite Path

**Lite Path:** A condensed, flattened workflow for small, well-scoped work. Entered directly by running a verb-first **shortcut** skill (e.g. `/aid-fix`, `/aid-create-api`) — not by TRIAGE routing inside `aid-describe`, which no longer exists. Every shortcut delegates to the shared **shortcut engine**, which collapses Describe→Define→Specify→Plan→Detail into one fast, mostly-autonomous run and produces the flattened artifact set (work-root `SPEC.md`, `PLAN.md`, `BLUEPRINT.md`, `tasks/task-NNN/DETAIL.md` — no `features/`, no `deliveries/`), then halts for approval before `/aid-execute`.

**TRIAGE:** Formerly the opening state of `aid-describe`; now extracted into the standalone `/aid-triage` skill (see [Off-Pipeline Skills](#off-pipeline-skills)). The routing judgment is unchanged in spirit — infer scope from a free-form description, then route — but `/aid-triage` is stateless and suggest-only: it never emits a work-root `SPEC.md` itself, it only names the next command to run.

**workType:** The internal classification of work, inferred during `/aid-triage`'s CLASSIFY state (never picked from a menu). Three values: `bug-fix`, `new-feature`, `refactor`. There is no separate document type — adding a document is a `new-feature`, changing one is a `refactor`. A coarse first-pass signal only; it narrows which shortcut-catalog groups are checked first and is not itself a routing target (there is no `LITE-BUG-FIX`/`LITE-REFACTOR`/`LITE-FEATURE` sub-path — that machinery was retired with the recipe catalog).

---

## Off-Pipeline Skills

**aid-housekeep:** One of AID's off-pipeline, on-demand skills (alongside `aid-update-kb`, `aid-summarize`, `aid-set-connector`, `aid-unset-connector`) within the 14 curated pipeline / on-demand / router skills — distinct from the 94-row shortcut catalog's skills (64 verb-first shortcut doorways + 30 `repurpose` skills). Run it whenever the Knowledge Base needs freshening. State machine: PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE, on an `aid/housekeep-*` branch. Not a numbered development phase.

**aid-query-kb:** Off-pipeline, on-demand Q&A skill — answers free-form questions about the project from the Knowledge Base, codebase, and in-flight works, with source citations. When context is insufficient, captures the gap as a Query-Gap entry in the KB's Q&A backlog (STATE.md) to feed the KB-improvement loop. Write scope is restricted to the gap-capture path — no KB doc, settings file, or code file is ever written. Run from any directory at any phase.

**aid-update-kb:** Off-pipeline, on-demand targeted KB update skill — takes a free-form prompt describing what changed and applies the delta to the affected KB docs, kept strictly bounded to the instruction (it never lifts extra content from the surrounding session). It isolates itself in its own git worktree, produces an Impact Map of where the instruction lands plus a minimal Scope Plan traced to it (with an explicit Not-Changing list), and pauses for an explicit human CONFIRM before any edit; it then applies only the confirmed scope, reviews the changed docs through the scoped review panel, and commits only after a second explicit `[1] Approved`. State machine: ANALYZE → SCOPE → CONFIRM → APPLY → REVIEW → APPROVAL → DONE (FIX loop inside REVIEW). Run it to keep the KB current after a change that bypassed the normal discovery cycle.

**aid-summarize:** Optional, idempotent, off-pipeline skill that generates `knowledge-summary.html` — an offline HTML viewer of the Knowledge Base. Can be run after any discovery cycle.

---

## The Shortcut System

**Shortcut:** One of 64 verb-first, direct-entry shortcut skills (e.g. `aid-fix`, `aid-create-api`, `aid-change-ui`) — the engine-generated thin doorways in the 94-row catalog (`canonical/aid/templates/shortcut-catalog.yml`). The catalog has 94 rows = 58 canonical names + 36 aliases; 64 rows are these engine-generated doorways and 30 are `repurpose: true` — hand-authored skills that each register their own directory (the 4 re-registered classic skills `aid-deploy` / `aid-monitor` / `aid-query-kb` / `aid-ask` plus 26 work-005 collapse & kind-sibling skills such as `aid-review`, `aid-research`, `aid-report`, `aid-document`, `aid-test`, `aid-prototype`, `aid-design`). Every one of the 94 rows owns a `canonical/skills/<name>/` directory. Naming your change with a shortcut is one of AID's three entry points, alongside `/aid-triage` and `/aid-describe`. Each engine-generated shortcut is a thin doorway that delegates to the shared shortcut engine.

**Shortcut engine:** The shared state machine (`canonical/aid/templates/shortcut-engine.md`) every shortcut delegates to: `INTAKE → CAPTURE → SPEC → PLAN → DETAIL → GATE → APPROVAL-HALT`. It collapses Describe→Define→Specify→Plan→Detail into one fast, mostly-autonomous run — it never skips a phase, it collapses the information capture within each. CAPTURE/SPEC/PLAN/DETAIL run without a per-phase human checkpoint (unlike the full path's Propose→Discuss→Write→Review loops); the only interactive moments are a rare CAPTURE gap-question and the terminal APPROVAL-HALT, where a mechanical GATE has graded every generated document. It never executes — `/aid-execute` is a separate, user-initiated run after approval. Replaces the retired recipe catalog; family-specific `shortcut-scaffolding/<family>.md` files supply the SPEC/PLAN/DETAIL scaffolding that recipes used to provide.

**`/aid-triage`:** A stateless, write-free, suggest-only router skill: `INTAKE → CLASSIFY → SUGGEST → HALT`. Captures one free-form description, infers `workType` and judges scope, then suggests exactly one next step — a specific shortcut for a known, single, well-scoped change, or the full path (`/aid-describe`) for anything broad, multi-activity, or ambiguous — and stops. It writes nothing: no work folder, no `STATE.md`, no interview, no subagent dispatch. The extraction of `aid-describe`'s former TRIAGE routing into its own skill.

---

## Artifacts

**SPEC.md:** Formal specification grounded in the Knowledge Base. Treated as a hypothesis — refined by evidence from implementation. In the full path, one SPEC.md lives under each feature (`.aid/works/{work}/features/{feature}/SPEC.md`, augmented with a Technical Specification by `aid-specify`). In the lite path, a single work-root SPEC.md covers the whole work item. Feature definition stays `SPEC.md` on both paths — only the delivery and task definitions were renamed (see `BLUEPRINT.md`, `DETAIL.md`).

**BLUEPRINT.md:** The delivery definition — scope, gate criteria, tasks, and dependencies for one delivery. Full path: `.aid/works/{work}/deliveries/delivery-NNN/BLUEPRINT.md`, one per delivery, written by `aid-plan`. Lite path: a single `BLUEPRINT.md` at the work root (no `deliveries/` nesting), written by the shortcut engine's SPEC/PLAN states. Formerly the delivery-level `SPEC.md` — renamed to disambiguate from the feature-level `SPEC.md`.

**DETAIL.md:** The task definition. Full path: `.aid/works/{work}/deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`, written by `aid-detail`. Lite path: `.aid/works/{work}/tasks/task-NNN/DETAIL.md` at the work root, written by the shortcut engine's DETAIL state. Formerly `tasks/task-NNN.md` (a flat file, not a folder) — now a per-task folder. On the full path that folder also holds a sibling `STATE.md`; the lite path has no per-task `STATE.md` — task cells live in the work-root `STATE.md` § `### Tasks lifecycle` instead.

**Q&A entry:** Appended to a STATE file (`.aid/knowledge/STATE.md` for discovery-area, `.aid/works/{work}/STATE.md` for work-area, or `.aid/works/{work}/features/{feature}/STATE.md` for feature-level) when a phase finds the Knowledge Base or an upstream artifact deficient. The owning phase resolves it on its next run — targeted, not a full restart.

**STATE.md:** The runtime state ledger for a given area. Post-FR2: discovery-area state lives at `.aid/knowledge/STATE.md`; work-area state at `.aid/works/{work}/STATE.md`; feature state at `.aid/works/{work}/features/{feature}/STATE.md`. Full path adds delivery-area state at `.aid/works/{work}/deliveries/delivery-NNN/STATE.md` and task-area state at `.aid/works/{work}/deliveries/delivery-NNN/tasks/task-NNN/STATE.md`. The lite path has no per-delivery or per-task `STATE.md` — the sole delivery's gate and Q&A, and every task's lifecycle cells, are promoted into the work-root `STATE.md` instead (§ `### Tasks lifecycle`). Holds Q&A history, review history, and calibration log.

**IMPEDIMENT.md:** Filed when implementation discovers the plan or spec is wrong. Contains: what was assumed, what's true, proposed revision, and impact assessment.

**Grading (A+ to F):** The review phase's quality scale. A+ (exemplary) through F (doesn't build). Evaluates spec compliance, architecture adherence, and convention conformance. Domain-specific quality checks are defined per project in SPEC.md.

---

## Groups

| Group | Phases / Skills | Focus |
|-------|-----------------|-------|
| **Support** | aid-config (+ set/unset-connector) | Bootstrap and configuration |
| **Knowledge Base Maintenance** | Discover (+ Summarize, Housekeep, Update-KB, Query-KB/Ask) | Build and maintain the Knowledge Base |
| **Definition** | Describe → Define, Specify, Plan, Detail (+ Triage, shortcuts, Deploy/Monitor) | Define the problem, plan it, and detail the work |
| **Execution** | Execute | Build, review, and test |

---

## Install Profiles

AID ships install bundles for five host AI tools:

| Profile | Install directory | Context file |
|---------|-------------------|--------------|
| **Claude Code** | `.claude/` | `CLAUDE.md` |
| **Codex CLI** | `.codex/` | `AGENTS.md` |
| **Cursor** | `.cursor/` | `AGENTS.md` |
| **GitHub Copilot CLI** | `.github/` | `AGENTS.md` |
| **Antigravity** | `.agent/` | `AGENTS.md` |

All five profiles contain byte-identical skill and agent bodies — only the wrapper format differs per tool. The source of truth is `canonical/`; profiles are generated output (never hand-edit them).

---

## Install and Distribution

**`aid` CLI:** The persistent global command installed once per machine. Provides `aid add / status / update / remove`. All install channels deliver the same CLI — only the method of putting it on PATH differs.

**Bootstrap:** The one-time step of installing the `aid` CLI onto a machine. Done via one of four channels: `curl | bash` (Linux/macOS), `irm | iex` (Windows PowerShell), `npm i -g aid-installer`, or `pipx install aid-installer`.

**Install channel:** The method by which the `aid` CLI was bootstrapped onto a machine. AID supports four live channels: `curl`/`irm` script, npm, and PyPI. A fifth path — offline bundle — is also available for air-gapped environments. The channel is recorded in `AID_INSTALL_CHANNEL`; `aid update self` reads it and prints the correct upgrade command.

**Profile:** The set of files `aid add <tool>` installs into a project. One profile per tool; profiles are generated from `canonical/` by the generator and stored in `profiles/<tool>/`.

**`--from-bundle` (offline bundle):** An installation mode that uses a locally-downloaded tarball instead of fetching from GitHub. Used for air-gapped or security-sensitive environments. Invoked as `aid add <tool> --from-bundle <path.tar.gz>`. Profile tarballs and `SHA256SUMS` are available on the [GitHub Releases page](https://github.com/AndreVianna/aid-methodology/releases).

**Protect-on-diff:** The behavior `aid add` (and `aid update`) uses when a root agent file (`CLAUDE.md` or `AGENTS.md`) already exists and was not written by AID. Instead of overwriting silently, AID writes the incoming version as `<file>.aid-new` and exits with a warning (exit 5). The user reviews the diff and merges manually, or re-runs with `--force` to overwrite.

---

## Declared Doc-Set

**Declared doc-set:** The KB document set for a project, defined in `.aid/settings.yml` under `discovery.doc_set`. The default seed is 14 standard documents. Because the set is declared (not ad-hoc), downstream skills navigate by convention — an agent looking for schemas always reads `schemas.md`; for tech debt, always `tech-debt.md`.

---

## Related Terms

**SDD (Spec-Driven Development):** A methodology where specifications drive code generation. AID contains SDD as a subset — the spec-and-build layer — and extends it with discovery, two-level planning, feedback loops, and post-deployment phases.

**Brownfield:** An existing codebase with history, technical debt, and undocumented knowledge. AID's Discovery phase is specifically designed for brownfield systems.

**Greenfield:** A new project with no existing code. In AID, greenfield projects run Init first, then skip Discovery and start at Describe (Phase 2a).

**Determinism Test:** Can you write a complete set of rules to validate the outcome? If yes, automate fully. If no, keep a human in the loop. Used to decide automation depth per phase.

**Canonical:** The `canonical/` directory — the single source of truth for all skill, agent, and template content. The generator (`run_generator.py`) renders `canonical/` into the five `profiles/` install trees. Never edit `profiles/` directly; edit `canonical/` and re-run the generator.
