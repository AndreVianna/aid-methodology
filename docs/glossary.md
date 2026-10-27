# AID Glossary

Terms used across AID, in alphabetical order.

## A

**Agent:** A role definition that a skill hands work to, for example `aid-developer` or `aid-reviewer`. The canonical set has nine agents (architect, clerk, developer, interviewer, operator, orchestrator, researcher, reviewer, tech-writer). Each agent has a tier (large, medium or small) that each tool maps to a model. Only the developer agent changes production code, and the agent that writes never grades its own work.

**AID (AI Integrated Development):** A method for building and maintaining software with AI agents, where you and the AI work through every phase together. It is delivered as skills (slash commands), agents, templates and scripts that your AI tool reads from the repo.

**AID region:** The text between `<!-- AID:BEGIN -->` and `<!-- AID:END -->` in a root instruction file (`AGENTS.md`, `CLAUDE.md`). AID writes only inside it. Text you wrote outside the markers is never changed.

**`aid` CLI:** The command installed once per machine. It provides `aid add`, `status`, `update`, `remove`, `dashboard`, `projects` and `chat`. Every install channel delivers the same CLI.

**Approval halt:** The last state of a shortcut run. The engine stops and waits for you to approve what it wrote before `/aid-execute` may run.

## B

**Bootstrap:** The one-time step of installing the `aid` CLI on a machine, through one of four channels: `curl | bash` (Linux/macOS), `irm | iex` (Windows PowerShell), `npm i -g aid-installer`, or `pipx install aid-installer`.

**Brownfield:** An existing codebase with history, technical debt and undocumented knowledge. The Discover phase is designed for it.

## C

**Canonical:** The `canonical/` directory, the single source of truth for skills, agents, the runtime and templates. Profiles and releases are built from it. Edit `canonical/`, never the generated output.

**Connector:** A short descriptor in `.aid/connectors/` that tells AID how to reach an outside tool such as a ticket tracker. It has a connection type (`mcp`, `api`, `ssh`, `cli` or `url`). For `mcp` your host tool owns the connection and AID stores no credential; other kinds name a secret by reference (an environment variable or file), never by value. Managed with `/aid-set-connector` and `/aid-unset-connector`.

## D

**Dashboard:** A local web view of every registered project's works, tasks and grades. Start it with `aid dashboard start`; it listens on `127.0.0.1` only. It reads the same `STATE.yml` files the skills write.

**Declared doc-set:** The Knowledge Base document list for a project, declared in `.aid/settings.yml` under `knowledge.doc_set`. The default seed is 14 documents. Because the set is declared, agents navigate by convention: schemas are always in `schemas.md`, tech debt in `tech-debt.md`.

**Declared review criteria:** What a reviewer checks a file against, written down rather than improvised. Criteria resolve at three levels and the reviewer checks the union: global and per-document-type criteria in `.aid/knowledge/authoring-conventions.md`, and per-file exceptions in the file's own `review-criteria:` frontmatter. The most specific level wins. Every finding cites the criterion `id` it breaks.

**Delivery:** A releasable slice of a work, with its own objective, scope and gate. On the full path each delivery is a `### delivery-NNN` stanza in `PLAN.md` and has its own folder with its own `STATE.yml`. A lite-path work has exactly one delivery and no `PLAN.md`.

**Design seed:** A `.aid/design/<artifact>.md` file that records a settled direction before it is built: the problem, the options, the current direction, the constraints and the open questions. `/aid-design` writes it; `/aid-create` consumes it. The lifecycle is design, then create, then update.

**DETAIL.md:** The definition of one task. Full path: `.aid/works/<work>/deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`, written by `aid-detail`. Lite path: `.aid/works/<work>/tasks/task-NNN/DETAIL.md`, written by the shortcut engine.

**Determinism test:** Can you write a complete set of rules to validate the outcome? If yes, automate fully. If no, keep a human in the loop. Used to decide how much to automate in each phase.

## E

**Entry point:** One of the three ways to start work: a verb-first shortcut, `/aid-triage`, or `/aid-describe`.

## F

**Feature section:** The formal specification of one feature, a `### Feature NNN` section under section 11 of `REQUIREMENTS.md`. It cites the requirements it implements and the acceptance criteria it owns, and gains a `#### Technical Specification` subsection when `aid-specify` runs. There is no separate per-feature spec file.

**Feedback loop:** A formal way for a later phase to revise earlier artifacts. AID defines eleven. Each leaves a record: a Q&A entry in a state file, an impediment file, or an `aid-monitor` finding.

## G

**Gate:** A point where work stops until a condition holds. There are two kinds. A human gate is an approval you give before the next phase starts. A quality gate is a review that must reach the minimum grade; the delivery gate does this for a whole delivery, and the shortcut engine's `GATE` state grades every generated document. See also **Phase gate**.

**Grade:** The quality score of a review, from A+ (no issues) down to F (does not build or run). The reviewer tags issues by severity and a script computes the grade, so the worst severity present sets the letter and the count sets the modifier. The reviewer never picks a grade by hand.

**Greenfield:** A new project with no existing code. Run `/aid-config`, skip Discover and start at Describe.

## I

**IMPEDIMENT.md:** A file filed when building shows that the plan or spec is wrong. It records what was assumed, what is true, the proposed revision and the impact.

**Install channel:** How the `aid` CLI got onto a machine: the curl/irm script, npm, or PyPI. An offline bundle is also supported. `aid update self` reads the recorded channel and uses the matching upgrade command.

**Iron Man model:** The human-AI philosophy behind AID. The AI is the suit that amplifies capability. You are the pilot who sets direction and decides.

## K

**Kind:** The second word of a shortcut that picks a specific artifact, as in `/aid-create api` or `/aid-update ui`. A kind has no skill folder of its own; it runs through its family's skill, which reads `shortcut-scaffolding/` for that family.

**Knowledge Base (KB):** The Markdown documents in `.aid/knowledge/` that capture the living understanding of a project: architecture, conventions, modules, schemas and more. The center of AID, ahead of the spec and the code. The default set has 14 standard documents plus generated `INDEX.md`, `README.md`, `STATE.md` and, when present, the project card. Skills read it before they change anything.

## L

**Lite path:** The condensed workflow for small, well-scoped work, entered by running a shortcut. The shortcut engine produces a flat set of files at the work root (`REQUIREMENTS.md`, `tasks/task-NNN/DETAIL.md`, no `features/` or `deliveries/` folders) and halts for your approval before `/aid-execute`. The opposite is the **full path**.

## M

**Minimum grade:** The grade a review must reach before its loop ends. It defaults to `A` and is set in `.aid/settings.yml` (`minimum_grade`) with `/aid-config`.

## O

**Off-pipeline skill:** A skill you run on demand, outside the numbered phases. Examples: `aid-housekeep`, `aid-update-kb`, `aid-ask`, `aid-summarize`, `aid-chat`, the connector skills and the ticket skills.

## P

**Phase:** One of the six numbered steps of the full path: Discover, Describe and Define (together phase 2), Specify, Plan, Detail, and Execute. Deploy and Monitor are optional and are not numbered phases.

**Phase gate:** A human decision point between phases. You review the output and approve before the next phase begins. The pipeline never advances on its own.

**Profile:** One tool's generated agents plus an `aid-tool.conf` descriptor, kept in `profiles/<tool>/`. The `profiles/<tool>.toml` files describe each tool's folder, model names and format. A profile holds no skills and no runtime.

**Project card:** `.aid/knowledge/PROJECT.md`, a one-page summary of the project: what it is, its stack, the build, test and lint commands, where things live and the rules that never bend. Agents read it first in every session.

**Projects registry:** The list of AID projects on your machine, kept by `aid projects` (`list`, `add`, `remove`, `scan`). `aid update all` and the dashboard use it.

## Q

**Q&A entry:** A question recorded in a state file when a phase finds the Knowledge Base or an upstream artifact deficient. The phase that owns the answer resolves it on its next run.

## R

**Runtime (`.aid/runtime/`):** The scripts, templates and `rules.md` that skills run against, installed once per repo from the shared payload. The `aid` CLI owns this folder; do not edit it.

## S

**SDD (Spec-Driven Development):** A method where specifications drive code generation. AID contains SDD as one layer, the spec-and-build span, and adds discovery, multi-level planning, feedback loops and post-deployment phases.

**Shared layout:** The current install layout: skills and runtime live once per repo (`.agents/skills/`, `.aid/runtime/`) and each tool keeps only its agents. `aid update` upgrades a repo from the older layout, which gave each tool its own folders, and moves the old files to `.aid/.trash/`.

**Shared payload:** The release artifact that holds the skills and the runtime, identical for every tool. It is installed once per repo.

**Shared skills (`.agents/skills/`):** The `aid-*` skill folders, installed once per repo. Claude Code also reads a byte-identical copy at `.claude/skills/`.

**Shortcut:** A verb-first command that names your change and starts the lite path, such as `/aid-fix` or `/aid-create api`. Each shortcut is a thin doorway into the shortcut engine. The catalog is `canonical/aid/templates/shortcut-catalog.yml`; every name in it is canonical, with no aliases.

**Shortcut engine:** The shared state machine every shortcut uses: `INTAKE`, `CAPTURE`, `SPEC`, `PLAN`, `DETAIL`, `GATE`, `APPROVAL-HALT`. It does the Describe-to-Detail work in one mostly autonomous run. It asks only a rare gap question during capture and stops for approval at the end. It never executes; `/aid-execute` is a separate run.

**Skill:** A slash command such as `/aid-fix`. It is an instruction document (`SKILL.md` and a `references/` folder) that your AI tool follows. The canonical set has 37 skills.

**STATE.yml:** The state record of a work, a delivery or a task: phase, lifecycle, approvals, grades and open questions. Work-level state is `.aid/works/<work>/STATE.yml`. A full-path work also has one per delivery and one per task. A lite-path work keeps its single delivery's gate and its task cells in the work's own `STATE.yml`. Only the `writeback-state.sh` script writes the machine-read fields. Discovery state is the separate `.aid/knowledge/STATE.md`.

## T

**Task:** The smallest unit of work, defined by one `DETAIL.md` and carrying a type such as implement, test, refactor, document or migrate. `/aid-execute` builds a task, reviews it and fixes it until it meets the minimum grade.

**Tier:** An agent's weight class: large, medium or small. Each tool maps a tier to one of its models, and a reviewer's tier is never lower than the executor's.

**`/aid-triage`:** A router skill that suggests which entry point fits. You describe the work in a sentence; it suggests one shortcut, the full path, or `/aid-ask`, and stops. It writes nothing.

## W

**Work:** One unit of change tracked from request to done, such as a bug fix, a feature or a design question. Each work has an id (`work-NNN-name`), a work folder and a `STATE.yml`.

**Work folder:** `.aid/works/work-NNN-name/`, the live files of one work: `STATE.yml`, `REQUIREMENTS.md`, `PLAN.md` (full path), the tasks and their `DETAIL.md` files. Work folders are transient. Nothing permanent, and nothing in the Knowledge Base, may depend on one.

**Worktree:** A separate git checkout of the same repo. Skills such as `aid-update-kb` and `aid-housekeep` work in their own worktree so your current tree stays untouched.
