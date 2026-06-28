# AID Glossary

Terms and concepts used throughout the AID methodology.

---

## Core Concepts

**AID (AI Integrated Development):** A structured methodology for building and maintaining software with AI agents. 6 numbered pipeline phases delivered by 14 skills across 5 groups; delivery (Deploy, Monitor), the summary skill, the on-demand Q&A skill, and the targeted KB update skill are optional. Human and AI co-execute every phase.

**Knowledge Base (KB):** 14 standard markdown documents (plus 3 meta-documents: INDEX, README, STATE) that capture the living understanding of a project. The gravitational center of AID — not the spec, not the code. Updated continuously across phases. The default set of 14 is configurable via `discovery.doc_set` in `.aid/settings.yml`. Note: "3 meta-documents" is a *role* distinction (generated/process ledgers, review-exempt) — it is orthogonal to the *concern* axis. A standard document (among the 14) may carry an *orientation* concern (cross-cutting, not mapped to a single spine dimension); `external-sources.md` is exactly this: it is a standard, authored, review-eligible KB document whose concern is orientation — orientation on the concern axis does not make a document a meta-document on the role axis.

**Feedback Loop:** A formal pathway for a downstream phase to revise upstream artifacts. Produces a formal record (a Q&A entry in a STATE file, an IMPEDIMENT file, or a MONITOR-STATE finding) with a revision trail.

**Phase Gate:** A human decision point between phases. The human reviews the phase output and approves advancement. "OK?" is the gate.

**Iron Man Model:** The human-AI collaboration philosophy. The AI is the suit (amplifies capability). The human is the pilot (sets direction, makes decisions). The human never leaves the cockpit.

---

## Setup

**aid-config:** Bootstrapping step that runs before the pipeline begins. Asks greenfield or brownfield, collects project metadata, and scaffolds the `.aid/knowledge/` directory with 14 empty KB document templates. Also creates `AGENTS.md`, `CLAUDE.md`, `README.md`, `INDEX.md`, and `STATE.md` placeholders. Not a methodology phase — it prepares the project so Discovery (or Interview) can begin cleanly.

---

## Phases

| Phase | Group | Produces |
|-------|-------|----------|
| **Discover** | Prepare | Knowledge Base (14 standard documents) |
| **Interview** | Define | Full path: `REQUIREMENTS.md` + per-feature `SPEC.md` stubs. Lite path: work-root `SPEC.md` + `tasks/` directly. |
| **Specify** | Define | Technical specification added to each feature's `SPEC.md` (full path only) |
| **Plan** | Map | `PLAN.md` (sequenced deliveries — full path only) |
| **Detail** | Map | Typed task files + execution graph (full path only) |
| **Execute** | Execute | Reviewed, graded code (8 task types, built-in review loop) |
| **Deploy** *(optional)* | Deliver | Shipped delivery, PR, KB update |
| **Monitor** *(optional)* | Deliver | Classified findings routed to fixes (BUG → lite bug-fix → Execute / CR → Interview / Infrastructure / No Action) |

> *Deploy and Monitor are **optional**, on-demand delivery skills positioned at the end of the pipeline — not required, numbered phases. Run them when the project's delivery model calls for them; neither presupposes the other.*

---

## The Lite Path

**Lite Path:** A condensed workflow for small, well-scoped work. Triggered by `aid-describe`'s TRIAGE state when your description yields a confident, single-target work-type and recipe match. Lite path skips `aid-specify`, `aid-plan`, and `aid-detail` — Interview emits a work-root `SPEC.md` + `tasks/` directly, then routes to `aid-execute`. A lite work can be escalated to full path mid-flight if scope grows.

**TRIAGE:** The opening state of `aid-describe`. Description-first: you describe the work in your own words, and the agent infers the work-type and the best-matching recipe (by reading each recipe's `summary:`), confirms in one turn, then routes — a confident single-target match to a lite sub-path, anything ambiguous/multi-target/broad to the full path.

**workType:** The internal classification of work, inferred by TRIAGE (never picked from a menu). Three values: `bug-fix`, `new-feature`, `refactor`. There is no separate document type — adding a document is a `new-feature`, changing one is a `refactor`.

**LITE-BUG-FIX:** Lite sub-path for bug fixes (`bug-fix`). Produces typically 1 IMPLEMENT task (fix + regression test).

**LITE-REFACTOR:** Lite sub-path for changing existing behavior (`refactor`, incl. changing docs/reports). Produces 1–3 REFACTOR + TEST tasks.

**LITE-FEATURE:** Lite sub-path for adding new functionality (`new-feature`, incl. adding docs/reports). Produces 1–5 IMPLEMENT + TEST + DOCUMENT tasks.

**Recipe:** A pre-filled lite-path template for a recurring work pattern. The catalog ships **51 recipes** at `canonical/recipes/`, named by the change they make — `add-X` / `change-X` / `fix-X` across target-kind families (e.g. `add-api-endpoint`, `change-ui-component`, `fix-regression`), plus refactor-only verbs (`improve-performance`, `bump-dependency`, `rename-symbol`) and one cross-type recipe (`add-test-coverage`). Shape: YAML frontmatter (incl. a one-line `summary:` TRIAGE matches against, and `applies-to` ∈ `{bug-fix, new-feature, refactor, *}`) + `## spec` block + `## tasks` block + `{{slot}}` placeholders substituted by `parse-recipe.sh`. Eliminates redundant interview for known patterns.

**summary (recipe field):** A one-line description in a recipe's YAML frontmatter. TRIAGE reads it to match a free-form work description to the right recipe.

**Slot:** A `{{placeholder}}` in a recipe that `parse-recipe.sh` substitutes with actual project-specific values before the tasks are executed.

---

## Off-Pipeline Skills

**aid-housekeep:** The 11th user-facing skill. On-demand, off the mandatory pipeline — run it whenever the Knowledge Base needs freshening. State machine: PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE, on an `aid/housekeep-*` branch. Not a numbered development phase.

**aid-query-kb:** The 12th user-facing skill. On-demand Q&A — answers free-form questions about the project from the Knowledge Base, codebase, and in-flight works, with source citations. When context is insufficient, captures the gap as a Query-Gap entry in the KB's Q&A backlog (STATE.md) to feed the KB-improvement loop. Write scope is restricted to the gap-capture path — no KB doc, settings file, or code file is ever written. Run from any directory at any phase.

**aid-update-kb:** The 13th user-facing skill. On-demand targeted KB update — takes a free-form prompt describing what changed and applies the delta to the affected KB docs through the same review gate as `/aid-discover` (ANALYZE→APPLY→REVIEW→APPROVAL→DONE). Human-gated: no change is committed without your explicit `[1] Approved`. Run it to keep the KB current after a change that bypassed the normal discovery cycle.

**aid-summarize:** Optional, idempotent skill that generates `knowledge-summary.html` — an offline HTML viewer of the Knowledge Base. Can be run after any discovery cycle.

---

## Artifacts

**SPEC.md:** Formal specification grounded in the Knowledge Base. Treated as a hypothesis — refined by evidence from implementation. In the full path, one SPEC.md lives under each feature. In the lite path, a single work-root SPEC.md covers the whole work item.

**Q&A entry:** Appended to a STATE file (`.aid/knowledge/STATE.md` for discovery-area, `.aid/{work}/STATE.md` for work-area, or `.aid/{work}/features/{feature}/STATE.md` for feature-level) when a phase finds the Knowledge Base or an upstream artifact deficient. The owning phase resolves it on its next run — targeted, not a full restart.

**STATE.md:** The runtime state ledger for a given area. Post-FR2: discovery-area state lives at `.aid/knowledge/STATE.md`; work-area state at `.aid/{work}/STATE.md`; feature state at `.aid/{work}/features/{feature}/STATE.md`. Holds Q&A history, review history, and calibration log.

**IMPEDIMENT.md:** Filed when implementation discovers the plan or spec is wrong. Contains: what was assumed, what's true, proposed revision, and impact assessment.

**Grading (A+ to F):** The review phase's quality scale. A+ (exemplary) through F (doesn't build). Evaluates spec compliance, architecture adherence, and convention conformance. Domain-specific quality checks are defined per project in SPEC.md.

---

## Groups

| Group | Phases | Focus |
|-------|--------|-------|
| **Prepare** | Discover (+ aid-config, aid-summarize) | Set up the workspace and understand the system |
| **Define** | Interview, Specify | Define the problem and how to solve it |
| **Map** | Plan, Detail | From requirements to an executable task list |
| **Execute** | Execute | Build, review, and test |
| **Deliver** | Deploy, Monitor *(optional)* | Optionally ship, monitor, and route what breaks |

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

**Greenfield:** A new project with no existing code. In AID, greenfield projects run Init first, then skip Discovery and start at Interview.

**Determinism Test:** Can you write a complete set of rules to validate the outcome? If yes, automate fully. If no, keep a human in the loop. Used to decide automation depth per phase.

**Canonical:** The `canonical/` directory — the single source of truth for all skill, agent, template, and recipe content. The generator (`run_generator.py`) renders `canonical/` into the five `profiles/` install trees. Never edit `profiles/` directly; edit `canonical/` and re-run the generator.
